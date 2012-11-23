require 'puppet/node'
require 'puppet/indirector/exec'

class Puppet::Node::Exec < Puppet::Indirector::Exec
  desc "Call an external program to get node information.  See
  the [External Nodes](http://docs.puppetlabs.com/guides/external_nodes.html) page for more information."
  include Puppet::Util

  def command
    command = Puppet[:external_nodes]
    raise ArgumentError, "You must set the 'external_nodes' parameter to use the external node terminus" unless command != "none"
    command.split
  end

  # Look for external node definitions.
  def find(request)
    output = super or return nil

    # Translate the output to ruby.
    result = translate(request.key, output)

    create_node(request.key, result)
  end

  private

  # Turn our outputted objects into a Puppet::Node instance.
  def create_node(name, result)
    node = Puppet::Node.new(name)
    set = false
    [:parameters, :classes, :environment].each do |param|
      if value = result[param]
        node.send(param.to_s + "=", value)
        set = true
      end
    end

    node.fact_merge
    node
  end

  # Translate the yaml string into Ruby objects.
  def translate(name, output)
    YAML.load(output).inject({}) do |hash, data|
      case data[0]
      when String
        hash[data[0].intern] = data[1]
      when Symbol
        hash[data[0]] = data[1]
      else
        raise Puppet::Error, "key is a #{data[0].class}, not a string or symbol"
      end

      hash
    end

  rescue => detail
      raise Puppet::Error, "Could not load external node results for #{name}: #{detail}"
  end
end