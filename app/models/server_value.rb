class ServerValue
  include Mongoid::Document

  # expected keys and value types are defined in blueprint.rb
  field :info, :type => Hash
  field :messages_total, :type => Hash
  field :messages_throughput, :type => Hash
  field :additional_fields, :type => Hash
  field :updated_at, :type => Fixnum

  %w(info messages_total messages_throughput additional_fields).each do |m|
    define_method(m) do
      read_attribute(m) || {}
    end
  end

  def updated_at
    Time.zone.at(read_attribute(:updated_at) || 0)
  end

  def startup_time
    Time.zone.at(info.fetch('startup_time', 0))
  end

  def alive?
    updated_at > 65.seconds.ago
  end

  def self.all_alive
    (all || []).select(&:alive?)
  end

  def self.all_alive?
    all_alive.count > 0
  end

  def self.total_current_messages_throughput
    aggregate_alive(:messages_throughput, 'current')
  end

  def self.total_highest_messages_throughput
    aggregate_alive(:messages_throughput, 'highest')
  end

  def self.remove_dead_servers
    all.each { |server| server.destroy unless server.alive? }
  end

private
  def self.aggregate_alive(field, key)
    all_alive.map(&field).map { |hash| hash.fetch(key, nil) }.compact.reduce(&:+) || 0
  end
end
