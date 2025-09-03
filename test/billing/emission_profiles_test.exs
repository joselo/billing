defmodule Billing.EmissionProfilesTest do
  use Billing.DataCase

  alias Billing.EmissionProfiles

  describe "emission_profiles" do
    alias Billing.EmissionProfiles.EmissionProfile

    import Billing.EmissionProfilesFixtures

    @invalid_attrs %{name: nil}

    test "list_emission_profiles/0 returns all emission_profiles" do
      emission_profile = emission_profile_fixture()
      assert EmissionProfiles.list_emission_profiles() == [emission_profile]
    end

    test "get_emission_profile!/1 returns the emission_profile with given id" do
      emission_profile = emission_profile_fixture()
      assert EmissionProfiles.get_emission_profile!(emission_profile.id) == emission_profile
    end

    test "create_emission_profile/1 with valid data creates a emission_profile" do
      valid_attrs = %{name: "some name"}

      assert {:ok, %EmissionProfile{} = emission_profile} = EmissionProfiles.create_emission_profile(valid_attrs)
      assert emission_profile.name == "some name"
    end

    test "create_emission_profile/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = EmissionProfiles.create_emission_profile(@invalid_attrs)
    end

    test "update_emission_profile/2 with valid data updates the emission_profile" do
      emission_profile = emission_profile_fixture()
      update_attrs = %{name: "some updated name"}

      assert {:ok, %EmissionProfile{} = emission_profile} = EmissionProfiles.update_emission_profile(emission_profile, update_attrs)
      assert emission_profile.name == "some updated name"
    end

    test "update_emission_profile/2 with invalid data returns error changeset" do
      emission_profile = emission_profile_fixture()
      assert {:error, %Ecto.Changeset{}} = EmissionProfiles.update_emission_profile(emission_profile, @invalid_attrs)
      assert emission_profile == EmissionProfiles.get_emission_profile!(emission_profile.id)
    end

    test "delete_emission_profile/1 deletes the emission_profile" do
      emission_profile = emission_profile_fixture()
      assert {:ok, %EmissionProfile{}} = EmissionProfiles.delete_emission_profile(emission_profile)
      assert_raise Ecto.NoResultsError, fn -> EmissionProfiles.get_emission_profile!(emission_profile.id) end
    end

    test "change_emission_profile/1 returns a emission_profile changeset" do
      emission_profile = emission_profile_fixture()
      assert %Ecto.Changeset{} = EmissionProfiles.change_emission_profile(emission_profile)
    end
  end
end
