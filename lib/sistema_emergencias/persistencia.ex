defmodule SistemaEmergencias.Persistencia do
  @moduledoc """
  Guarda y recupera información del sistema en archivos de texto.
  """

  @archivos %{
    usuarios: "usuarios.txt",
    zonas: "zonas.txt",
    necesidades: "necesidades.txt",
    recursos: "recursos.txt",
    personas: "personas.txt",
    mensajes: "mensajes.txt",
    mascotas: "mascotas.txt",
    albergues: "albergues.txt"
  }

  def guardar(nombre, datos) do
  directorio = Path.expand("../../priv/datos", __DIR__)
  guardar_en(directorio, nombre, datos)
end

def cargar(nombre) do
  directorio = Path.expand("../../priv/datos", __DIR__)
  cargar_desde(directorio, nombre)
end

  def guardar_en(directorio, nombre, datos) do
    with {:ok, archivo} <- obtener_archivo(nombre),
         :ok <- File.mkdir_p(directorio) do
      ruta = Path.join(directorio, archivo)
      contenido = datos |> :erlang.term_to_binary() |> Base.encode64()

      case File.write(ruta, contenido) do
        :ok -> {:ok, "Información guardada correctamente en #{archivo}"}
        {:error, razon} -> {:error, "No fue posible guardar: #{inspect(razon)}"}
      end
    end
  end

  def cargar_desde(directorio, nombre) do
    with {:ok, archivo} <- obtener_archivo(nombre) do
      ruta = Path.join(directorio, archivo)

      case File.read(ruta) do
        {:ok, contenido} ->
          with {:ok, binario} <- Base.decode64(contenido),
               datos <- :erlang.binary_to_term(binario) do
            {:ok, datos}
          else
            _ -> {:error, "El archivo contiene información inválida"}
          end

        {:error, :enoent} ->
          {:ok, []}

        {:error, razon} ->
          {:error, "No fue posible leer el archivo: #{inspect(razon)}"}
      end
    end
  rescue
    _ -> {:error, "No fue posible interpretar la información guardada"}
  end

  defp obtener_archivo(nombre) do
    case Map.fetch(@archivos, nombre) do
      {:ok, archivo} -> {:ok, archivo}
      :error -> {:error, "Nombre de archivo no permitido"}
    end
  end
end
