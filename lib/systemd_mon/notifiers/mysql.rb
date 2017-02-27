require 'systemd_mon/error'
require 'systemd_mon/notifiers/base'

begin
  require 'mysql'
rescue LoadError
  raise SystemdMon::NotifierDependencyError, "The 'mysql' gem is required by the mysql notifier"
end

module SystemdMon::Notifiers
  class Mysql < Base

    def notify!(notification)

      service = notification.unit.name.split(".").first
      status = notification.unit.current_state.first

      case notification.hostname
        when "ip-10-150-107-232"
          env = "testing"
        when "ip-10-150-105-208"
          env = "production"
        else
          # Default to production
          env = "production"
      end

      output = `systemctl show #{service}`
      topic = output[/--topic=(.*?) --queue/, 1]
      queue = output[/--queue=(.*?) --group/, 1]
      group = output[/--group=(.*?) 2>&1/, 1]

      update topic, status, queue, group, env
    end

    def update(topic, state, queue, group, env)
      con = ::Mysql.new(options['hostname'], options['username'], options['password'], options['database']);
      query = "INSERT INTO #{options['table']} SET topic='#{topic}', state='#{state}', queue='#{queue}', groupname='#{group}', env='#{env}'"
      log "Sending update to Mysql:" + query
      con.query(query)
      con.close
    end
  end
end
