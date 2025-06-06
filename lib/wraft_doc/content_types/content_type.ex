defmodule WraftDoc.ContentTypes.ContentType do
  @moduledoc """
    The content type model.
  """
  @behaviour ExTypesense

  use WraftDoc.Schema

  alias __MODULE__
  alias WraftDoc.ContentTypes.ContentType
  alias WraftDoc.Enterprise.Flow
  alias WraftDoc.Layouts.Layout
  alias WraftDoc.Themes.Theme

  @document_type [:contract, :document]
  @derive {Jason.Encoder, only: [:id]}

  schema "content_type" do
    field(:name, :string)
    field(:description, :string)
    field(:color, :string)
    field(:prefix, :string)
    field(:type, Ecto.Enum, values: @document_type, default: :document)
    field(:frame_mapping, {:array, :map})

    belongs_to(:layout, Layout)
    belongs_to(:creator, WraftDoc.Account.User)
    belongs_to(:organisation, WraftDoc.Enterprise.Organisation)
    belongs_to(:flow, Flow)
    belongs_to(:theme, Theme)

    has_many(:instances, WraftDoc.Documents.Instance)
    has_many(:content_type_fields, WraftDoc.ContentTypes.ContentTypeField)
    has_many(:fields, through: [:content_type_fields, :field])
    has_many(:stages, WraftDoc.Pipelines.Stages.Stage)
    has_many(:pipelines, through: [:stages, :pipeline])
    has_many(:content_type_roles, WraftDoc.ContentTypes.ContentTypeRole)
    has_many(:roles, through: [:content_type_roles, :role])

    timestamps()
  end

  def changeset(%ContentType{} = content_type, attrs \\ %{}) do
    content_type
    |> cast(
      attrs,
      [
        :name,
        :description,
        :type,
        :prefix,
        :color,
        :frame_mapping,
        :layout_id,
        :flow_id,
        :theme_id,
        :organisation_id,
        :creator_id
      ]
    )
    |> validate_required([
      :name,
      :prefix,
      :layout_id,
      :flow_id,
      :theme_id,
      :organisation_id,
      :creator_id
    ])
    |> unique_constraint(
      :name,
      message: "Content type with the same name under your organisation exists.!",
      name: :content_type_organisation_unique_index
    )
    |> validate_length(:prefix, min: 2, max: 6)
    |> validate_format(:color, ~r/^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$/)
  end

  def update_changeset(%ContentType{} = content_type, attrs \\ %{}) do
    content_type
    |> cast(attrs, [
      :name,
      :description,
      :type,
      :color,
      :frame_mapping,
      :layout_id,
      :flow_id,
      :prefix,
      :theme_id
    ])
    |> validate_required([:name, :description, :layout_id, :flow_id, :prefix, :theme_id])
    |> unique_constraint(
      :name,
      message: "Content type with the same name under your organisation exists.!",
      name: :content_type_organisation_unique_index
    )
    |> organisation_constraint(Layout, :layout_id)
    |> organisation_constraint(Flow, :flow_id)
    |> organisation_constraint(Theme, :theme_id)
    |> validate_length(:prefix, min: 2, max: 6)
    |> validate_format(:color, ~r/^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$/)
  end

  @impl ExTypesense

  def get_field_types do
    %{
      fields: [
        %{name: "id", type: "string", facet: false},
        %{name: "name", type: "string", facet: true},
        %{name: "description", type: "string", facet: false},
        %{name: "color", type: "string", facet: true},
        %{name: "prefix", type: "string", facet: true},
        %{name: "layout_id", type: "string", facet: true},
        %{name: "flow_id", type: "string", facet: true},
        %{name: "theme_id", type: "string", facet: true},
        %{name: "organisation_id", type: "string", facet: true},
        %{name: "creator_id", type: "string", facet: true},
        %{name: "inserted_at", type: "int64", facet: false},
        %{name: "updated_at", type: "int64", facet: false}
      ]
    }
  end
end
