defmodule Inmobiliaria.Application do

  use Application

  def start(_type, _args) do

    children = [{Inmobiliaria.Supervisor,[]},{Inmobiliaria.PropertyManager,[]}]
    opts = [strategy: :one_for_one,name: Inmobiliaria.MainSupervisor]

    Supervisor.start_link(children,opts)
  end
end
