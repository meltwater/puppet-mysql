require 'puppet/provider/package'

Puppet::Type.type(:mysql_database).provide(:mysql,
		:parent => Puppet::Provider::Package) do

	desc "Use mysql as database."
	commands :mysqladmin => '/usr/bin/mysqladmin'
	commands :mysql => '/usr/bin/mysql'

	# retrieve the current set of mysql users
	def self.instances
		dbs = []

		cmd = "#{command(:mysql)} --defaults-file=/root/.my.cnf mysql -NBe 'show databases'"
		execpipe(cmd) do |process|
			process.each do |line|
				dbs << new( { :ensure => :present, :name => line.chomp } )
			end
		end
		return dbs
	end

	def query
		result = {
			:name => @resource[:name],
			:ensure => :absent
		}

		cmd = "#{command(:mysql)} --defaults-file=/root/.my.cnf mysql -NBe 'show databases'"
		execpipe(cmd) do |process|
			process.each do |line|
				if line.chomp.eql?(@resource[:name])
					result[:ensure] = :present
				end
			end
		end
		result
	end

	def create
		mysqladmin "--defaults-file=/root/.my.cnf", "create", @resource[:name]
	end
	def destroy
		mysqladmin "--defaults-file=/root/.my.cnf", "-f", "drop", @resource[:name]
	end

	def exists?
		if mysql("mysql", "--defaults-file=/root/.my.cnf", "-NBe", "show databases").match(/^#{@resource[:name]}$/)
			true
		else
			false
		end
	end
end

