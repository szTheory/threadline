defmodule Threadline.OperatorSurface.StressRouterProdCompile.Router do
  use Phoenix.Router
  require Threadline.OperatorSurface.StressRouter

  pipeline :browser do
    plug(:accepts, ["html"])
  end

  scope "/" do
    pipe_through(:browser)

    Threadline.OperatorSurface.StressRouter.threadline_operator_surface_stress("/__stress",
      authorize_fn: fn _ -> true end
    )
  end
end
