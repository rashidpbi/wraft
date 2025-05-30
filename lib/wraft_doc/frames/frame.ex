defmodule WraftDoc.Frames.Frame do
  @moduledoc false
  use Waffle.Ecto.Schema
  use WraftDoc.Schema

  alias WraftDoc.Account.User
  alias WraftDoc.Assets.Asset
  alias WraftDoc.Enterprise.Organisation

  schema "frame" do
    field(:name, :string)
    field(:description, :string)
    field(:type, Ecto.Enum, values: [:latex, :typst])
    field(:file_size, :string)
    field(:wraft_json, :map)
    field(:thumbnail, WraftDocWeb.FrameThumbnailUploader.Type)
    field(:fields, {:array, :map}, default: [])

    belongs_to(:asset, Asset)
    belongs_to(:creator, User)
    belongs_to(:organisation, Organisation)

    timestamps()
  end

  def changeset(frame, attrs) do
    frame
    |> cast(attrs, [
      :name,
      :description,
      :type,
      :fields,
      :asset_id,
      :organisation_id,
      :creator_id,
      :wraft_json,
      :file_size
    ])
    |> cast_attachments(attrs, [:thumbnail])
    |> validate_required([:name, :description, :type, :organisation_id])
    |> unique_constraint(:name,
      name: :frame_name_organisation_id_index,
      message: "Frame with the same name  under your organisation exists.!"
    )
  end

  def admin_changeset(frame, attrs) do
    frame
    |> cast(attrs, [
      :name,
      :description,
      :type,
      :asset_id,
      :fields,
      :organisation_id,
      :creator_id,
      :wraft_json,
      :file_size
    ])
    |> cast_attachments(attrs, [:thumbnail])
    |> validate_required([:name, :description, :type, :organisation_id])
    |> unique_constraint(:name,
      name: :frame_name_organisation_id_index,
      message: "Frame with the same name  under your organisation exists.!"
    )
  end

  def update_changeset(frame, attrs) do
    frame
    |> cast(attrs, [
      :name,
      :description,
      :type,
      :asset_id,
      :fields,
      :organisation_id,
      :creator_id,
      :wraft_json,
      :file_size
    ])
    |> cast_attachments(attrs, [:thumbnail])
    |> validate_required([:name, :description, :type])
    |> unique_constraint(:name,
      name: :frame_name_organisation_id_index,
      message: "Frame with the same name  under your organisation exists.!"
    )
  end
end
