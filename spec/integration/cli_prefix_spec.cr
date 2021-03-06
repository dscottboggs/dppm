require "../../src/cli"

module IntegrationSpec
  def build_package(prefix_path : String, package : String)
    it "builds an application" do
      pkg = CLI::Pkg.build(
        no_confirm: true,
        config: DPPM_CONFIG_FILE,
        source: SAMPLES_DIR,
        prefix: prefix_path,
        package: package,
        custom_vars: Array(String).new)
      pkg.name.starts_with?(TEST_APP_PACKAGE_NAME).should be_true
      Dir.exists?(pkg.path).should be_true
    end
  end

  def add_application(prefix_path : String, application : String, name : String)
    it "adds an application" do
      app = CLI::App.add(
        no_confirm: true,
        config: DPPM_CONFIG_FILE,
        source: SAMPLES_DIR,
        prefix: prefix_path,
        application: application,
        name: name,
        contained: false,
        noservice: true,
        socket: false)
      app.name.starts_with?(TEST_APP_PACKAGE_NAME).should be_true
    end
  end

  def delete_application(prefix_path : String, application : String)
    it "deletes an application" do
      delete = CLI::App.delete(
        no_confirm: true,
        prefix: prefix_path,
        application: application,
        keep_user_group: false,
        preserve_database: false).not_nil!
      delete.name.should eq TEST_APP_PACKAGE_NAME
      Dir.exists?(delete.path).should be_false
    end
  end
end
