# Stubs, no database, used to exercise migrations-path resolution.
defmodule Threadline.TestSupport.CustomPrivRepo do
  @moduledoc false
  def config, do: [priv: "priv/custom_repo"]
end

defmodule Threadline.TestSupport.NoPrivRepo do
  @moduledoc false
  def config, do: []
end

defmodule Threadline.TestSupport.BrokenConfigRepo do
  @moduledoc false
  def config, do: raise(ArgumentError, "no :otp_app config")
end
