# Add JSON generated column with secondary index for country-code attribute to improve query performance.
Sequel.migration do
  up do
    # JSON generated-column feature requires MySQL 5.7.13.
    unless database_type == :mysql
      raise "MySQL database is required for JSON generated column feature.
You are currently using #{database_type}.
Set up a MySQL database and retry the migration."
    end

    unless server_version >= 50713
      raise "MySQL 5.7.13 (50713) or greater is required for JSON generated column feature.
You are currently using version #{server_version}.
Upgrade your MySQL server and retry the migration."
    end

    run <<~MySQL
      ALTER TABLE `forms`
        ADD `location_country_code_s` CHAR(2)
          GENERATED ALWAYS AS (processed_data->>"$.location_country_code_s") VIRTUAL;
    MySQL

    alter_table(:forms) do
      add_index [:kind, :location_country_code_s]
    end
  end

  down do
    alter_table(:forms) do
      drop_index [:kind, :location_country_code_s]
      drop_column :location_country_code_s
    end
  end
end
