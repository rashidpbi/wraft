defmodule WraftDoc.AuthorizationTest do
  use WraftDoc.DataCase

  alias WraftDoc.Authorization
  alias WraftDoc.Authorization.Permission

  @resource_count 36

  describe "list_permissions/0" do
    test "lists all permissions grouped by resource" do
      resources = Authorization.list_resources()
      permissions_by_resources = Authorization.list_permissions(%{})

      assert resources
             |> Enum.map(&Map.has_key?(permissions_by_resources, &1))
             |> Enum.all?()
    end

    test "filter by name" do
      permission = insert(:permission, name: "layout:custom_permission", resource: "Layout")
      permissions_by_resources = Authorization.list_permissions(%{"name" => "custom"})

      assert %{"Layout" => [^permission]} = permissions_by_resources
    end

    test "returns an empty map when there are no matches for name keyword" do
      permissions_by_resources = Authorization.list_permissions(%{"name" => "does not exist"})
      assert permissions_by_resources == %{}
    end

    test "filter by resource" do
      permissions_by_resources = Authorization.list_permissions(%{"resource" => "Layout"})

      # Checks that there is only one matching resource
      assert map_size(permissions_by_resources) == 1

      # Checks that the only matching resource availabe in the response is Layout
      assert %{"Layout" => _permissions} = permissions_by_resources
    end

    test "returns an empty map when there are no matches for resource keyword" do
      permissions_by_resources = Authorization.list_permissions(%{"resource" => "does not exist"})
      assert permissions_by_resources == %{}
    end
  end

  describe "list_resources/0" do
    test "lists all 32 resources we have in Wraft" do
      assert @resource_count = Enum.count(Authorization.list_resources())
    end
  end

  describe "create_permission/1" do
    test "creates a permission with valid params" do
      params = %{name: "new_resource:manage", resource: "New Resource", action: "Manage"}

      assert {:ok, %Permission{} = permission} = Authorization.create_permission(params)
      assert permission.name == "new_resource:manage"
      assert permission.resource == "New Resource"
      assert permission.action == "Manage"
    end

    test "returns error changeset with invalid params" do
      params = %{name: nil, resource: "New Resource", action: "Manage"}

      assert {:error, changeset} = Authorization.create_permission(params)
      assert %{name: ["can't be blank"]} == errors_on(changeset)
    end
  end

  describe "get_permission/1" do
    test "returns permission struct with valid ID" do
      %{id: permission_id} = Repo.get_by(Permission, name: "layout:manage")
      assert %Permission{name: "layout:manage"} = Authorization.get_permission(permission_id)
    end

    test "returns nil with non existent ID" do
      assert nil == Authorization.get_permission(Faker.UUID.v4())
    end
  end

  describe "delete_permission/1" do
    test "deletes a permission with valid input" do
      permission = Repo.get_by(Permission, name: "layout:manage")

      assert {:ok, %Permission{name: "layout:manage"}} =
               Authorization.delete_permission(permission)
    end
  end
end
