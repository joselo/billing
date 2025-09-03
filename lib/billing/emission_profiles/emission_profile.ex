defmodule Billing.EmissionProfiles.EmissionProfile do
  use Ecto.Schema
  import Ecto.Changeset

  schema "emission_profiles" do
    belongs_to :certificate, Billing.Certificates.Certificate
    belongs_to :company, Billing.Companies.Company

    field :name, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(emission_profile, attrs) do
    emission_profile
    |> cast(attrs, [:name, :certificate_id, :company_id])
    |> validate_required([:name, :certificate_id, :company_id])
  end
end
