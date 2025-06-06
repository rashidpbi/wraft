defmodule WraftDocWeb.Api.V1.TemplateAssetController do
  use WraftDocWeb, :controller
  use PhoenixSwagger

  plug WraftDocWeb.Plug.AddActionLog

  action_fallback(WraftDocWeb.FallbackController)

  alias WraftDoc.ContentTypes
  alias WraftDoc.DataTemplates
  alias WraftDoc.Layouts
  alias WraftDoc.TemplateAssets
  alias WraftDoc.TemplateAssets.TemplateAsset
  alias WraftDoc.Themes

  @doc """
  Creates a new template asset.
  """
  def swagger_definitions do
    %{
      TemplateAsset:
        swagger_schema do
          title("Template Asset")
          description("A Template asset bundle.")

          properties do
            id(:string, "The ID of the template asset", required: true, format: "uuid")
            name(:string, "Name of the template asset")
            file(:string, "URL of the uploaded file")
            inserted_at(:string, "When the template asset was inserted", format: "ISO-8601")
            updated_at(:string, "When the template asset was last updated", format: "ISO-8601")
          end

          example(%{
            id: "1232148nb3478",
            name: "Template Asset",
            file: "/contract.zip",
            file_entries: [
              "wraft.json",
              "theme/HubotSans-RegularItalic.otf",
              "theme/HubotSans-Regular.otf",
              "theme/HubotSans-BoldItalic.otf",
              "theme/HubotSans-Bold.otf",
              "theme/",
              "template.json",
              "layout/gradient.pdf",
              "layout/",
              "contract/template.tex",
              "contract/"
            ],
            wraft_json: %{
              data_template: "data_template/",
              layout: "layout/gradient.pdf",
              flow: "flow/",
              theme: "theme/",
              contract: "contract/"
            },
            updated_at: "2020-01-21T14:00:00Z",
            inserted_at: "2020-02-21T14:00:00Z"
          })
        end,
      ShowTemplateAsset:
        swagger_schema do
          title("Show template asset")
          description("A template asset and its details")

          properties do
            template_asset(Schema.ref(:TemplateAsset))
            creator(Schema.ref(:User))
          end

          example(%{
            template_asset: %{
              id: "1232148nb3478",
              name: "Template Asset",
              file: "/contract.zip",
              updated_at: "2020-01-21T14:00:00Z",
              inserted_at: "2020-02-21T14:00:00Z"
            },
            creator: %{
              id: "1232148nb3478",
              name: "John Doe",
              email: "email@xyz.com",
              email_verify: true,
              updated_at: "2020-01-21T14:00:00Z",
              inserted_at: "2020-02-21T14:00:00Z"
            }
          })
        end,
      TemplateAssets:
        swagger_schema do
          title("All template assets in an organisation")
          description("All template assets that have been created under an organisation")
          type(:array)
          items(Schema.ref(:TemplateAsset))
        end,
      TemplateAssetsIndex:
        swagger_schema do
          properties do
            template_assets(Schema.ref(:TemplateAssets))
            page_number(:integer, "Page number")
            total_pages(:integer, "Total number of pages")
            total_entries(:integer, "Total number of contents")
          end

          example(%{
            template_assets: [
              %{
                id: "1232148nb3478",
                name: "Template Asset",
                file: "/contract.zip",
                updated_at: "2020-01-21T14:00:00Z",
                inserted_at: "2020-02-21T14:00:00Z"
              }
            ],
            page_number: 1,
            total_pages: 2,
            total_entries: 15
          })
        end,
      PublicTemplateList:
        swagger_schema do
          title("Public Template List")
          description("A list of public templates, each with a file name and path.")
          type(:object)

          properties do
            templates(%Schema{
              type: :array,
              description: "List of templates with file name and path",
              items: %Schema{
                type: :object,
                properties: %{
                  id: %Schema{type: :string, description: "Template asset id"},
                  name: %Schema{type: :string, description: "Template asset name"},
                  description: %Schema{
                    type: :string,
                    description: "Template asset description"
                  },
                  file_name: %Schema{type: :string, description: "The name of the file"},
                  zip_file_url: %Schema{
                    type: :string,
                    description: "URL of the zip file in the template asset"
                  },
                  thumbnail_url: %Schema{
                    type: :string,
                    description: "URL of the thumbnail image of the template asset"
                  }
                }
              }
            })
          end

          example(%{
            templates: [
              %{
                id: "53d2de6d-e0ad-4c5a-a302-6af54fa36920",
                name: "Contract",
                description: "description",
                file_name: "contract",
                file_size: "94.38 KB",
                thumbnail_url:
                  "http://minio.example.com/wraft/public/templates/contract-template/thumbnail.png",
                zip_file_url:
                  "http://minio.example.com/wraft/public/templates/contract-template/zip_file.zip"
              },
              %{
                id: "53d2de6d-e0ad-4c5a-a302-6af54fa36920",
                name: "Contract",
                description: "description",
                file_name: "contract",
                file_size: "94.38 KB",
                thumbnail_url:
                  "http://minio.example.com/wraft/public/templates/contract-template/thumbnail.png",
                zip_file_url:
                  "http://minio.example.com/wraft/public/templates/contract-template/zip_file.zip"
              }
            ]
          })
        end,
      DownloadTemplateResponse:
        swagger_schema do
          title("Download Template Response")
          description("Response containing the pre-signed URL for downloading the template.")
          type(:object)

          properties do
            template_url(:string, "Pre-signed URL for downloading the template",
              example:
                "https://minio.example.com/bucket/templates/example-template.zip?X-Amz-Signature=..."
            )
          end
        end,
      FileDownloadResponse:
        swagger_schema do
          title("File Download Response")
          description("Response for a file download.")
          type(:file)
          example("Binary data representing the downloaded file.")
        end,
      TemplateImport:
        swagger_schema do
          title("Template Import Response")
          description("Response containing details of imported template components")

          properties do
            message(:string, "Status message of the import operation")

            items(%Schema{
              type: :array,
              description: "List of imported template components",
              items: %Schema{
                type: :object,
                properties: %{
                  item_type: %Schema{
                    type: :string,
                    description: "Type of the imported item",
                    enum: ["flow", "data_template", "layout", "theme", "variant"]
                  },
                  id: %Schema{
                    type: :string,
                    description: "Unique identifier of the imported item",
                    format: "uuid"
                  },
                  name: %Schema{
                    type: :string,
                    description: "Name of the imported item (for most item types)"
                  },
                  title: %Schema{
                    type: :string,
                    description: "Title of the imported item (for data_template)"
                  },
                  created_at: %Schema{
                    type: :string,
                    description: "Timestamp of item creation",
                    format: "date-time"
                  }
                }
              }
            })
          end

          example(%{
            message: "Template imported successfully",
            items: [
              %{
                item_type: "flow",
                id: "dc0c7d4c-1328-45c0-ba3b-af841f7f5b59",
                name: "Contract flow 23",
                created_at: "2024-11-26T21:18:35"
              },
              %{
                item_type: "data_template",
                id: "98f49a33-5a5f-4455-910c-11f7f3e1a575",
                title: "Contract 33",
                created_at: "2024-11-26T21:18:36"
              }
            ]
          })
        end,
      TemplatePreImport:
        swagger_schema do
          title("Template Pre-Import Response")

          description(
            "Response containing existing and missing items for template import preparation"
          )

          properties do
            missing_items(%Schema{
              type: :array,
              description: "List of item types missing from the template asset",
              items: %Schema{
                type: :string,
                enum: ["layout", "theme", "flow", "data_template", "variant"]
              }
            })

            existing_items(%Schema{
              type: :object,
              description: "Details of existing items in the template asset",
              properties: %{
                data_template: %Schema{
                  type: :object,
                  description: "Existing data template details",
                  properties: %{
                    title: %Schema{type: :string, description: "Title of the data template"},
                    title_template: %Schema{type: :string, description: "Template for the title"}
                  }
                },
                variant: %Schema{
                  type: :object,
                  description: "Existing variant details",
                  properties: %{
                    name: %Schema{type: :string, description: "Name of the variant"},
                    description: %Schema{type: :string, description: "Description of the variant"},
                    prefix: %Schema{type: :string, description: "Prefix for the variant"}
                  }
                }
              }
            })
          end

          example(%{
            missing_items: ["layout", "theme", "flow"],
            existing_items: %{
              data_template: %{
                title: "Contract",
                title_template: "Contract for [clientName]"
              },
              variant: %{
                name: "Contract",
                description: "Variant for contract layouts",
                prefix: "CTR"
              }
            }
          })
        end
    }
  end

  @doc """
  Create a template asset.
  """
  swagger_path :create do
    post("/template_assets")
    summary("Create a template asset")

    description("""
    Create a new template asset by either:
    - Uploading a ZIP file
    - Providing a URL to a ZIP file

    Only one of `asset_id` with type template_asset or `zip_url` should be provided.
    """)

    consumes("multipart/form-data")

    parameter(:file, :formData, :file, "Asset id")

    response(200, "OK", Schema.ref(:TemplateAsset))
    response(422, "Unprocessable Entity", Schema.ref(:Error))
    response(401, "Unauthorized", Schema.ref(:Error))
  end

  @spec create(Plug.Conn.t(), map) :: Plug.Conn.t()
  def create(conn, %{"file" => file} = params) do
    current_user = conn.assigns.current_user

    with :ok <- TemplateAssets.validate_template_asset_file(file),
         {:ok, params, _} <-
           TemplateAssets.process_template_asset(params, :file, file),
         {:ok, %TemplateAsset{} = template_asset} <-
           TemplateAssets.create_template_asset(current_user, params) do
      render(conn, "template_asset.json", template_asset: template_asset)
    end
  end

  # This function is currently not in use but is retained for potential future implementation.
  # @spec create(Plug.Conn.t(), map) :: Plug.Conn.t()
  # def create(conn, %{"zip_url" => zip_url} = params) do
  #   current_user = conn.assigns.current_user

  #   with :ok <- TemplateAssets.validate_template_asset_file(file),
  #   {:ok, params, file_binary} <-
  #          TemplateAssets.process_template_asset(params, :url, zip_url),
  #        {:ok, %TemplateAsset{} = template_asset} <-
  #          TemplateAssets.create_template_asset(current_user, params),
  #        {:ok, _} <-
  #          TemplateAssets.add_asset(template_asset, file_binary, zip_url, current_user) do
  #     render(conn, "template_asset.json", template_asset: template_asset)
  #   end
  # end

  @doc """
  Template Asset index.
  """
  swagger_path :index do
    get("/template_assets")
    summary("Template Asset index")
    description("API to get the list of all template assets created so far under an organisation")

    parameter(:page, :query, :integer, "Page number")

    response(200, "Ok", Schema.ref(:TemplateAssetsIndex))
    response(401, "Unauthorized", Schema.ref(:Error))
  end

  @spec index(Plug.Conn.t(), map) :: Plug.Conn.t()
  def index(conn, params) do
    current_user = conn.assigns[:current_user]

    with %{
           entries: template_assets,
           page_number: page_number,
           total_pages: total_pages,
           total_entries: total_entries
         } <- TemplateAssets.template_asset_index(current_user, params) do
      render(conn, "index.json",
        template_assets: template_assets,
        page_number: page_number,
        total_pages: total_pages,
        total_entries: total_entries
      )
    end
  end

  @doc """
  Show template asset.
  """
  swagger_path :show do
    get("/template_assets/{id}")
    summary("Show a template asset")
    description("API to get all details of a template asset")

    parameters do
      id(:path, :string, "ID of the template asset", required: true)
    end

    response(200, "Ok", Schema.ref(:ShowTemplateAsset))
    response(404, "Not found", Schema.ref(:Error))
    response(401, "Unauthorized", Schema.ref(:Error))
  end

  @spec show(Plug.Conn.t(), map) :: Plug.Conn.t()
  def show(conn, %{"id" => template_asset_id}) do
    current_user = conn.assigns.current_user

    with %TemplateAsset{} = template_asset <-
           TemplateAssets.show_template_asset(template_asset_id, current_user) do
      render(conn, "show.json", template_asset: template_asset)
    end
  end

  @doc """
  Delete a template asset.
  """
  swagger_path :delete do
    PhoenixSwagger.Path.delete("/template_assets/{id}")
    summary("Delete a template asset")
    description("API to delete a template asset")

    parameters do
      id(:path, :string, "template asset id", required: true)
    end

    response(200, "Ok", Schema.ref(:TemplateAsset))
    response(422, "Unprocessable Entity", Schema.ref(:Error))
    response(401, "Unauthorized", Schema.ref(:Error))
    response(404, "Not found", Schema.ref(:Error))
  end

  @spec delete(Plug.Conn.t(), map) :: Plug.Conn.t()
  def delete(conn, %{"id" => id}) do
    current_user = conn.assigns[:current_user]

    with %TemplateAsset{} = template_asset <- TemplateAssets.get_template_asset(id, current_user),
         {:ok, %TemplateAsset{}} <- TemplateAssets.delete_template_asset(template_asset) do
      render(conn, "template_asset.json", template_asset: template_asset)
    end
  end

  @doc """
  Builds a template from an existing template asset.
  """
  swagger_path :template_import do
    post("/template_assets/{id}/import")
    summary("Build a template from an existing template asset")

    description(
      "Build a data template from a template asset to be used for document creation or further customization."
    )

    operation_id("build_template")
    consumes("application/json")

    parameters do
      id(:path, :string, "ID of the template asset to build", required: true)
      theme_id(:formData, :string, "ID of the theme to build the template from")
      flow_id(:formData, :string, "ID of the flow to build the template from")
      frame_id(:formData, :string, "ID of the frame to build the template from")
      layout_id(:formData, :string, "ID of the layout to build the template from")
      content_type_id(:formData, :string, "ID of the content type to build the template from")
    end

    response(200, "Ok", Schema.ref(:TemplateImport))
    response(422, "Unprocessable Entity", Schema.ref(:Error))
    response(404, "Not found", Schema.ref(:Error))
    response(401, "Unauthorized", Schema.ref(:Error))
  end

  @spec template_import(Plug.Conn.t(), map) :: Plug.Conn.t()
  def template_import(conn, %{"id" => template_asset_id} = params) do
    current_user = conn.assigns[:current_user]

    with %TemplateAsset{asset: asset} <-
           TemplateAssets.get_template_asset(template_asset_id, current_user),
         {:ok, downloaded_file_binary} <-
           TemplateAssets.download_zip_from_storage(asset),
         options <- TemplateAssets.format_opts(params),
         {:ok, result} <-
           TemplateAssets.import_template(current_user, downloaded_file_binary, options) do
      render(conn, "show_template.json", result: result)
    end
  end

  @doc """
  Checks for the missing items in template asset and makes user include the missing item ids in actual import.
  """
  swagger_path :template_pre_import do
    get("/template_assets/{id}/pre_import")
    summary("Prepare template asset for import")

    description(
      "Check for missing items in template asset and identify what needs to be included"
    )

    operation_id("pre_import_template")
    consumes("application/json")

    parameters do
      id(:path, :string, "ID of the template asset to pre-import", required: true)
    end

    response(200, "Ok", Schema.ref(:TemplatePreImport))
    response(404, "Not found", Schema.ref(:Error))
    response(401, "Unauthorized", Schema.ref(:Error))
  end

  @spec template_pre_import(Plug.Conn.t(), map) :: Plug.Conn.t()
  def template_pre_import(conn, %{"id" => template_asset_id}) do
    current_user = conn.assigns[:current_user]

    with %TemplateAsset{asset: asset} <-
           TemplateAssets.get_template_asset(template_asset_id, current_user),
         {:ok, downloaded_file_binary} <-
           TemplateAssets.download_zip_from_storage(asset),
         {:ok, result} <-
           TemplateAssets.pre_import_template(downloaded_file_binary) do
      render(conn, "template_pre_import.json", result: result)
    end
  end

  @doc """
  Template asset export.
  """
  swagger_path :template_export do
    post("/template_assets/{id}/export/")
    summary("Export data template into a zip format")

    description("
  This creates a zip file containing all assets of data template from its id")

    operation_id("template_export")
    consumes("application/json")

    parameters do
      id(:path, :string, "ID of the template asset to build", required: true)
    end

    response(200, "Ok", Schema.ref(:FileDownloadResponse))
    response(422, "Unprocessable Entity", Schema.ref(:Error))
    response(404, "Not found", Schema.ref(:Error))
    response(401, "Unauthorized", Schema.ref(:Error))
  end

  @spec template_export(Plug.Conn.t(), map) :: Plug.Conn.t()
  def template_export(conn, %{"id" => id}) do
    current_user = conn.assigns.current_user

    with %WraftDoc.DataTemplates.DataTemplate{} = data_template <-
           DataTemplates.get_data_template(current_user, id),
         %WraftDoc.ContentTypes.ContentType{} = c_type <-
           ContentTypes.get_content_type(current_user, data_template.content_type_id),
         %WraftDoc.Layouts.Layout{} = layout <-
           Layouts.get_layout(c_type.layout_id, current_user),
         %WraftDoc.Themes.Theme{} = theme <-
           Themes.get_theme(c_type.theme_id, current_user),
         {:ok, zip_path} <-
           TemplateAssets.prepare_template_format(
             theme,
             layout,
             c_type,
             data_template,
             current_user
           ) do
      send_download(conn, {:file, zip_path}, filename: "#{data_template.title}.zip")
    end
  end

  @doc """
  List all templates.
  """
  swagger_path :list_public_templates do
    get("/template_assets/public/templates")
    summary("List Public Templates")
    description("Fetches a list of all public templates available.")
    produces("application/json")
    response(200, "Success", Schema.ref(:PublicTemplateList))
    response(400, "Bad Request", Schema.ref(:Error))
  end

  def list_public_templates(conn, _params) do
    with {:ok, template_list} <- TemplateAssets.public_template_asset_index() do
      render(conn, "list_public_templates.json", %{templates: template_list})
    end
  end

  @doc """
  Download a public template.
  """
  swagger_path :download_public_template do
    get("/template_assets/public/templates/:file_name/download")
    summary("Get Download URL for Public Template")
    description("Generates a pre-signed URL for downloading a specified public template file.")
    produces("application/json")
    parameter(:file_name, :path, :string, "Name of the template file to download", required: true)
    response(200, "Pre-signed URL generated successfully", Schema.ref(:DownloadTemplateResponse))
    response(400, "Failed to generate pre-signed URL", Schema.ref(:Error))
  end

  def download_public_template(conn, %{"file_name" => template_name}) do
    with {:ok, template_url} <- TemplateAssets.download_public_template(template_name) do
      render(conn, "download_public_template.json", %{template_url: template_url})
    end
  end

  @doc """
  Builds a template from an existing template asset.
  """
  swagger_path :import_public_template do
    post("/template_assets/public/{id}/install")
    summary("Import template from public template asset")

    description(
      "Import a data template from a public template asset to be used for document creation or further customization."
    )

    operation_id("build_template")
    consumes("application/json")

    parameters do
      id(:path, :string, "ID of the template asset to build", required: true)
      theme_id(:formData, :string, "ID of the theme to build the template from")
      frame_id(:formData, :string, "ID of the frame to build the template from")
      flow_id(:formData, :string, "ID of the flow to build the template from")
      layout_id(:formData, :string, "ID of the layout to build the template from")
      content_type_id(:formData, :string, "ID of the content type to build the template from")
    end

    response(200, "Ok", Schema.ref(:TemplateImport))
    response(422, "Unprocessable Entity", Schema.ref(:Error))
    response(404, "Not found", Schema.ref(:Error))
    response(401, "Unauthorized", Schema.ref(:Error))
  end

  def import_public_template(conn, %{"id" => template_asset_id} = params) do
    current_user = conn.assigns[:current_user]

    with %TemplateAsset{} = template_asset <-
           TemplateAssets.get_template_asset(template_asset_id),
         {:ok, downloaded_file_binary} <-
           TemplateAssets.download_zip_from_storage(template_asset),
         options <- TemplateAssets.format_opts(params),
         {:ok, result} <-
           TemplateAssets.import_template(current_user, downloaded_file_binary, options) do
      render(conn, "show_template.json", result: result)
    end
  end
end
