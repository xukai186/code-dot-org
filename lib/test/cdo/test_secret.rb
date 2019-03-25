require_relative '../test_helper'
require 'cdo/secret'

class SecretTest < Minitest::Test
  # Test the various use-cases of the secrets API.
  def test_secret
    values = {
      'shared/cdo/secret' => 'test123',
      'env/cdo/z' => 'testz',
      'x/y/z' => 'testxyz'
    }
    client = Aws::SecretsManager::Client.new(
      stub_responses: {
        get_secret_value: ->(ctx) do
          id = ctx.params[:secret_id]
          raise Cdo::Secrets::NOT_FOUND.new(nil, '') unless (value = values[id])
          {secret_string: value}
        end
      }
    )
    secrets = Cdo::Secrets.new(
      paths: %w(env/cdo/ shared/cdo/),
      client: client
    )

    secrets_config = YAML.load <<YAML
# Various example use-cases for !Secret tag:

# Fetch `secret`.
secret: !Secret

# Fetch `z`.
secret2: !Secret z

# Fetch fully-qualified `x/y/z`.
secret3: !Secret x/y/z

# Fetch `missing_key`, or `'not a secret!'` if not found.
secret4: !Secret [missing_key, 'not a secret!']

# Fetch fully-qualified `x/y/z`, or `'not a secret!'` if not found.
secret5: !Secret [x/y/z, 'not a secret!']
YAML
    Cdo::Secret.resolve!(secrets_config, secrets)

    # Ensure secret values are correctly lazy-loaded.
    assert_equal 0, api_requests(client)

    assert_equal 'test123', secrets_config['secret']
    assert_equal 2, api_requests(client)

    assert_equal 'testz', secrets_config['secret2']
    assert_equal 3, api_requests(client)

    e = assert_raises(Cdo::Secrets::NOT_FOUND) do
      secrets.required!
    end
    assert_match /Key: missing_key/, e.message

    assert_equal 6, api_requests(client)

    assert_equal 'testxyz', secrets_config['secret3']
    assert_equal 'not a secret!', secrets_config['secret4']
    assert_equal 'testxyz', secrets_config['secret5']
  end

  private

  def api_requests(client)
    client.api_requests.count {|req| req[:operation_name] == :get_secret_value}
  end
end
