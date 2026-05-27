defmodule Threadline.Evidence.SubjectTest do
  use ExUnit.Case, async: true

  alias Threadline.Evidence.Subject

  test "accepts the supported Threadline-owned evidence subject set" do
    Enum.each(Subject.supported_subjects(), fn supported_subject ->
      assert :ok = Subject.validate(supported_subject)
      assert :ok = Subject.validate(String.to_atom(supported_subject))
      assert :ok = Subject.validate(%{subject: supported_subject})
      assert :ok = Subject.validate(%{"subject" => supported_subject})
      assert Subject.supported?(supported_subject)
    end)
  end

  test "rejects unsupported host-owned and compliance-platform subjects" do
    Enum.each(
      [
        "rbac_policy",
        "tenant_membership",
        "approval_workflow",
        "legal_hold",
        "vendor_report_pack"
      ],
      fn unsupported_subject ->
        assert {:error, {:unsupported_subject, ^unsupported_subject}} =
                 Subject.validate(unsupported_subject)

        refute Subject.supported?(unsupported_subject)
      end
    )
  end

  test "keeps the unsupported error stable for unsupported descriptors" do
    assert {:error, {:unsupported_subject, "legal_hold"}} =
             Subject.validate(%{subject: "legal_hold"})

    assert {:error, {:unsupported_subject, "rbac_policy"}} =
             Subject.validate(%{"subject" => "rbac_policy"})
  end
end
