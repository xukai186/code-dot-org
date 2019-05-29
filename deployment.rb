$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift File.expand_path('../shared/middleware', __FILE__)

# Set up gems listed in the Gemfile.
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __FILE__)
require 'bundler/setup' if File.exist?(ENV['BUNDLE_GEMFILE'])

require 'csv'
require 'cdo/yaml'
require 'cdo/erb'
require 'cdo/slog'
require 'os'
require 'cdo/git_utils'
require 'uri'

# Since channel ids are derived from user id and other sequential integer ids
# use a new S3 sources directory for each Test Build to prevent a UI test
# from inadvertently using a channel id from a previous Test Build.
# CircleCI environments already override the sources_s3_directory setting to suffix it with the Circle Build number:
# https://github.com/code-dot-org/code-dot-org/blob/fb53af48ec0598692ed19f340f26d2ed0bd9547b/.circleci/config.yml#L153
# Detect Circle environment just to be safe.
def sources_s3_dir(environment, project_directory)
  if environment == :production
    'sources'
  elsif environment == :test && !ENV['CIRCLECI']
    "sources_#{environment}/#{GitUtils.git_revision_short(project_directory)}"
  else
    "sources_#{environment}"
  end
end

####################################################################################################
##
## CDO - A singleton that contains our settings and integration helpers.
##
##########
require 'cdo/config'
class CDOImpl < Cdo::Config
  @slog = nil

  def canonical_hostname(domain)
    # Allow hostname overrides
    return CDO.override_dashboard if CDO.override_dashboard && domain == 'studio.code.org'
    return CDO.override_pegasus if CDO.override_pegasus && domain == 'code.org'

    return "#{name}.#{domain}" if ['console', 'hoc-levels'].include?(name)
    return domain if rack_env?(:production)

    # our HTTPS wildcard certificate only supports *.code.org
    # 'env', 'studio.code.org' over https must resolve to 'env-studio.code.org' for non-prod environments
    sep = (domain.include?('.code.org')) ? '-' : '.'
    return "localhost#{sep}#{domain}" if rack_env?(:development)
    return "translate#{sep}#{domain}" if name == 'crowdin'
    "#{rack_env}#{sep}#{domain}"
  end

  def dashboard_hostname
    canonical_hostname('studio.code.org')
  end

  def pegasus_hostname
    canonical_hostname('code.org')
  end

  def hourofcode_hostname
    canonical_hostname('hourofcode.com')
  end

  def advocacy_hostname
    canonical_hostname('advocacy.code.org')
  end

  def circle_run_identifier
    ENV['CIRCLE_BUILD_NUM'] ? "CIRCLE-BUILD-#{ENV['CIRCLE_BUILD_NUM']}-#{ENV['CIRCLE_NODE_INDEX']}" : nil
  end

  # provide a unique path for firebase channels data for development and circleci,
  # to avoid conflicts in channel ids.
  def firebase_channel_id_suffix
    return "-#{circle_run_identifier}" if ENV['CI']
    return "-DEVELOPMENT-#{ENV['USER']}" if CDO.firebase_name == 'cdo-v3-dev'
    ''
  end

  def site_host(domain)
    host = canonical_hostname(domain)
    if (rack_env?(:development) && !CDO.https_development) ||
      (ENV['CI'] && host.include?('localhost'))
      port = ['studio.code.org'].include?(domain) ? CDO.dashboard_port : CDO.pegasus_port
      host += ":#{port}"
    end
    host
  end

  def site_url(domain, path = '', scheme = '')
    path = '/' + path unless path.empty? || path[0] == '/'
    "#{scheme}//#{site_host(domain)}#{path}"
  end

  def studio_url(path = '', scheme = '')
    site_url('studio.code.org', path, scheme)
  end

  def code_org_url(path = '', scheme = '')
    site_url('code.org', path, scheme)
  end

  def advocacy_url(path = '', scheme = '')
    site_url('advocacy.code.org', path, scheme)
  end

  def hourofcode_url(path = '', scheme = '')
    site_url('hourofcode.com', path, scheme)
  end

  # NOTE: When a new language is added to this set, make sure to also update
  # the redirection rules for the cdo-curriculum S3 bucket by running the
  # aws/s3/cdo-curriculum/redirection_rules.rb script. Otherwise, all links to
  # CB for that language will attempt to point to the language-specific version
  # of that content, even if we haven't translated that content yet.
  #
  # See the LANGUAGES setting in
  # https://github.com/mrjoshida/curriculumbuilder/blob/master/curriculumBuilder/settings.py
  # for the languages currently supported in CurriculumBuilder itself
  CURRICULUM_LANGUAGES = Set['es-mx', 'it-it', 'th-th', 'sk-sk']

  def curriculum_url(locale, path = '')
    locale = locale.downcase.to_s
    uri = URI("https://curriculum.code.org")
    path = File.join(locale, path) if CURRICULUM_LANGUAGES.include? locale
    uri += path
    uri.to_s
  end

  def default_scheme
    rack_env?(:development) || ENV['CI'] ? 'http:' : 'https:'
  end

  def dir(*dirs)
    File.join(root_dir, *dirs)
  end

  def hosts_by_env(env)
    hosts = []
    GlobalConfig['hosts'].each_pair do |_key, i|
      hosts << i if i['env'] == env.to_s
    end
    hosts
  end

  def hostnames_by_env(env)
    hosts_by_env(env).map {|i| i['name']}
  end

  def rack_env?(env)
    rack_env.to_sym == env.to_sym
  end

  # Sets the slogger to use in a test.
  # slogger must support a `write` method.
  def set_slogger_for_test(slogger)
    @slog = slogger
    # Set a fake slog token so that the slog method will actually call
    # the test slogger.
    CDO.slog_token = 'fake_slog_token'
  end

  def slog(params)
    return unless slog_token && Gatekeeper.allows('slogging', default: true)
    @slog ||= Slog::Writer.new(secret: slog_token)
    @slog.write params
  end

  def shared_image_url(path)
    "/shared/images/#{path}"
  end

  # Default logger implementation
  attr_writer :log
  def log
    @log ||= Logger.new(STDOUT).tap do |l|
      l.level = Logger::INFO
      l.formatter = proc do |severity, _, _, msg|
        "#{severity != 'INFO' ? "#{severity}: " : ''}#{msg}\n"
      end
    end
  end

  # Simple backtrace filter
  FILTER_GEMS = %w(rake).freeze

  def backtrace(exception)
    filter_backtrace exception.backtrace
  end

  def filter_backtrace(backtrace)
    FILTER_GEMS.map do |gem|
      backtrace.reject! {|b| b =~ /gems\/#{gem}/}
    end
    backtrace.each do |b|
      b.gsub!(CDO.dir, '[CDO]')
      Gem.path.each do |gem|
        b.gsub!(gem, '[GEM]')
      end
      b.gsub! Bundler.system_bindir, '[BIN]'
    end
    backtrace.join("\n")
  end

  class DelegateWithDefault < SimpleDelegator
    def initialize(target, default_value)
      @default_value = default_value
      super(target)
    end

    def method_missing(*args)
      return @default_value unless __getobj__.respond_to? args.first
      value = super
      return @default_value if value.nil?
      value
    end
  end

  def with_default(default_value)
    DelegateWithDefault.new(self, default_value)
  end

  # When running on Chef Server, use EC2 API to fetch a dynamic list of app-server front-ends,
  # appending to the static list already provided by configuration files.
  def app_servers
    return super unless CDO.chef_managed
    require 'aws-sdk-ec2'
    servers = Aws::EC2::Client.new.describe_instances(
      filters: [
        {name: 'tag:aws:cloudformation:stack-name', values: [CDO.stack_name]},
        {name: 'tag:aws:cloudformation:logical-id', values: ['Frontends']},
        {name: 'instance-state-name', values: ['running']}
      ]
    ).reservations.map(&:instances).flatten.map {|i| ["fe-#{i.instance_id}", i.private_dns_name]}.to_h
    servers.merge(super)
  end
end

CDO ||= CDOImpl.instance

# Set AWS SDK environment variables from provided config and standardize on aws_* attributes
ENV['AWS_ACCESS_KEY_ID'] ||= CDO.aws_access_key ||= CDO.s3_access_key_id
ENV['AWS_SECRET_ACCESS_KEY'] ||= CDO.aws_secret_key ||= CDO.s3_secret_access_key

# AWS Ruby SDK doesn't auto-detect region from EC2 Instance Metadata.
# Ref: https://github.com/aws/aws-sdk-ruby/issues/1455
ENV['AWS_DEFAULT_REGION'] ||= CDO.aws_region

require 'cdo/aws/cdo_google_credentials'

require 'cdo/secrets'
CDO.secrets = Cdo::Secrets.new(paths: CDO.secrets_paths)

####################################################################################################
##
## Helpers
##
##########

def rack_env
  CDO.rack_env.to_sym
end

def rack_env?(*env)
  e = *env
  e.include? rack_env.to_sym
end

def with_rack_env(temporary_env)
  previous_env = CDO.rack_env
  CDO.rack_env = temporary_env
  yield
  CDO.rack_env = previous_env
end

def deploy_dir(*dirs)
  CDO.dir(*dirs)
end

def aws_dir(*dirs)
  deploy_dir('aws', *dirs)
end

def apps_dir(*dirs)
  deploy_dir('apps', *dirs)
end

def tools_dir(*dirs)
  deploy_dir('tools', *dirs)
end

def cookbooks_dir(*dirs)
  deploy_dir('cookbooks', *dirs)
end

def dashboard_dir(*dirs)
  deploy_dir('dashboard', *dirs)
end

def pegasus_dir(*paths)
  deploy_dir('pegasus', *paths)
end

def shared_dir(*dirs)
  deploy_dir('shared', *dirs)
end

def shared_js_dir(*dirs)
  deploy_dir('shared/js', *dirs)
end

def lib_dir(*dirs)
  deploy_dir('lib', *dirs)
end

def shared_constants_dir(*dirs)
  lib_dir('cdo', 'shared_constants', *dirs)
end

def shared_constants_file
  lib_dir('cdo', 'shared_constants.rb')
end
