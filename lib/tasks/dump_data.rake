require_relative '../record_migrator'

namespace :db do

  desc "Dump pre-2.0 request data from the current enviroment's DB into JSON"
    task data_dump: :environment do
      Rails.application.eager_load!
      [ ContractorRequest, StaffRequest, LaborRequest ]
        .each { |klass| klass.include(TwoPointOhMigrator) }
       
      File.open(Rails.root.join("tmp/requests.json") , 'w') do |file|
        file << ActiveRecord::Base.subclasses
          .select { |klass|  %w[ ContractorRequest LaborRequest StaffRequest ].include? klass.name }
          .map(&:all).map(&:to_a).flatten.map(&:to_v2).to_json
      end
    end

end
