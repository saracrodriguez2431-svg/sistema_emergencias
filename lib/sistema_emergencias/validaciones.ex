defmodule SistemaEmergencias.Validaciones do
  @moduledoc """
  Funciones generales para validar los datos
  ingresados en el sistema de emergencias.
  """

  def texto_obligatorio(texto) when is_binary(texto) do
    if String.trim(texto) != "" do
      {:ok, texto}
    else
      {:error, "El campo no puede estar vacio"}
    end
  end

  def texto_obligatorio(_texto) do
    {:error, "El valor debe ser un texto"}
  end

  def entero_no_negativo(numero)
      when is_integer(numero) and numero >= 0 do
    {:ok, numero}
  end

  def entero_no_negativo(_numero) do
    {:error, "El valor debe ser un entero no negativo"}
  end

  def numero_no_negativo(numero)
      when is_number(numero) and numero >= 0 do
    {:ok, numero}
  end

  def numero_no_negativo(_numero) do
    {:error, "El valor debe ser un numero no negativo"}
  end

  def id_unico(id, identificadores) when is_list(identificadores) do
    if id in identificadores do
      {:error, "El identificador ya existe"}
    else
      {:ok, id}
    end
  end

  def id_unico(_id, _identificadores) do
    {:error, "La lista de identificadores no es valida"}
  end
end
