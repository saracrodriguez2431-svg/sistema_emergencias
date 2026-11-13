defmodule WebWeb.DashboardLive do
  use WebWeb, :live_view

  alias SistemaEmergencias.Gestor
  alias SistemaEmergencias.Necesidades
  alias SistemaEmergencias.Recursos
  alias SistemaEmergencias.Usuarios
  alias SistemaEmergencias.Zonas
  alias SistemaEmergencias.Personas
  alias SistemaEmergencias.Mensajes
  alias SistemaEmergencias.Mascotas
  alias SistemaEmergencias.Albergues

  @modulos [
    {"Resumen general", :resumen},
    {"Usuarios", :usuarios},
    {"Zonas y sectores", :zonas},
    {"Necesidades", :necesidades},
    {"Recursos e inventario", :recursos},
    {"Personas afectadas", :personas},
    {"Comunicación familiar", :mensajes},
    {"Mascotas", :mascotas},
    {"Albergues", :albergues}
  ]

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:modulos, @modulos)
      |> assign(:seccion, :resumen)
      |> assign(:mensaje, nil)
      |> assign(:error, nil)
      |> assign(:coincidencias, [])

    {:ok, cargar_datos(socket)}
  end

  @impl true
  def handle_event("actualizar", _params, socket) do
    {:noreply, cargar_datos(socket)}
  end

  def handle_event("cambiar_seccion", %{"seccion" => seccion}, socket) do
    clave =
      Enum.find_value(@modulos, :resumen, fn {_, valor} ->
        if Atom.to_string(valor) == seccion, do: valor
      end)

    {:noreply,
     assign(socket,
       seccion: clave,
       mensaje: nil,
       error: nil,
       coincidencias: []
     )}
  end

  # =========================================================
  # NECESIDADES
  # =========================================================

  def handle_event("registrar_necesidad", params, socket) do
    with {:ok, cantidad} <- entero(params["cantidad"]) do
      necesidad = %{
        id: params["registro_id"],
        tipo: params["tipo"],
        descripcion: params["descripcion"],
        cantidad: cantidad,
        zona: params["zona"],
        prioridad: params["prioridad"],
        responsable: params["responsable"]
      }

      resultado =
        Necesidades.registrar(necesidad, socket.assigns.estado.necesidades)

      guardar_resultado(resultado, socket, :necesidades, "Necesidad registrada correctamente")
    else
      {:error, razon} -> error(socket, razon)
    end
    |> responder()
  end

  def handle_event("asignar_necesidad", params, socket) do
    resultado =
      Necesidades.asignar(
        params["registro_id"],
        params["responsable"],
        socket.assigns.estado.necesidades
      )

    guardar_resultado(resultado, socket, :necesidades, "Responsable asignado correctamente")
    |> responder()
  end

  def handle_event("cambiar_estado_necesidad", params, socket) do
    resultado =
      Necesidades.cambiar_estado(
        params["registro_id"],
        params["estado"],
        socket.assigns.estado.necesidades
      )

    guardar_resultado(resultado, socket, :necesidades, "Estado actualizado correctamente")
    |> responder()
  end

  # =========================================================
  # RECURSOS
  # =========================================================

  def handle_event("registrar_recurso", params, socket) do
    with {:ok, cantidad} <- entero(params["cantidad"]) do
      recurso = %{
        codigo: params["codigo"],
        nombre: params["nombre"],
        categoria: params["categoria"],
        cantidad: cantidad,
        unidad: params["unidad"],
        ubicacion: params["ubicacion"]
      }

      resultado = Recursos.registrar(recurso, socket.assigns.estado.recursos)

      guardar_resultado(resultado, socket, :recursos, "Recurso registrado correctamente")
    else
      {:error, razon} -> error(socket, razon)
    end
    |> responder()
  end

  def handle_event("movimiento_recurso", params, socket) do
    with {:ok, cantidad} <- entero(params["cantidad"]) do
      recursos = socket.assigns.estado.recursos

      resultado =
        case params["operacion"] do
          "entrada" ->
            Recursos.entrada(params["codigo"], cantidad, recursos)

          "salida" ->
            Recursos.salida(params["codigo"], cantidad, recursos)

          "transferencia" ->
            Recursos.transferir(params["codigo"], cantidad, params["destino"], recursos)

          _ ->
            {:error, "Selecciona un movimiento válido"}
        end

      guardar_resultado(resultado, socket, :recursos, "Movimiento registrado correctamente")
    else
      {:error, razon} -> error(socket, razon)
    end
    |> responder()
  end

  # =========================================================
  # USUARIOS
  # =========================================================

  def handle_event("registrar_usuario", params, socket) do
    usuario = %{
      id: params["registro_id"],
      nombre: params["nombre"],
      correo: params["correo"],
      clave: params["clave"],
      rol: params["rol"]
    }

    resultado = Usuarios.registrar(usuario, socket.assigns.estado.usuarios)

    guardar_resultado(resultado, socket, :usuarios, "Usuario registrado correctamente")
    |> responder()
  end

  def handle_event("iniciar_sesion_usuario", params, socket) do
    resultado =
      Usuarios.iniciar_sesion(
        params["registro_id"],
        params["clave"],
        socket.assigns.estado.usuarios
      )

    guardar_resultado(resultado, socket, :usuarios, "Sesión iniciada correctamente")
    |> responder()
  end

  def handle_event("cerrar_sesion_usuario", params, socket) do
    resultado =
      Usuarios.cerrar_sesion(
        params["registro_id"],
        socket.assigns.estado.usuarios
      )

    guardar_resultado(resultado, socket, :usuarios, "Sesión cerrada correctamente")
    |> responder()
  end

  # =========================================================
  # ZONAS, SECTORES Y PUNTOS
  # =========================================================

  def handle_event("registrar_zona", params, socket) do
    zona = %{
      id: params["registro_id"],
      nombre: params["nombre"],
      nivel: params["nivel"]
    }

    resultado = Zonas.registrar_zona(zona, socket.assigns.estado.zonas)

    guardar_resultado(resultado, socket, :zonas, "Zona registrada correctamente")
    |> responder()
  end

  def handle_event("agregar_sector", params, socket) do
    sector = %{id: params["registro_id"], nombre: params["nombre"]}

    resultado =
      Zonas.agregar_sector(
        params["zona_id"],
        sector,
        socket.assigns.estado.zonas
      )

    guardar_resultado(resultado, socket, :zonas, "Sector agregado correctamente")
    |> responder()
  end

  def handle_event("agregar_punto", params, socket) do
    punto = %{
      id: params["registro_id"],
      nombre: params["nombre"],
      direccion: params["direccion"]
    }

    resultado =
      Zonas.agregar_punto(
        params["zona_id"],
        params["sector_id"],
        punto,
        socket.assigns.estado.zonas
      )

    guardar_resultado(resultado, socket, :zonas, "Punto de atención agregado correctamente")
    |> responder()
  end

  # =========================================================
  # PERSONAS AFECTADAS
  # =========================================================

  def handle_event("registrar_persona", params, socket) do
    with {:ok, edad} <- entero(params["edad"]) do
      persona = %{
        id: params["registro_id"],
        nombre: params["nombre"],
        documento: params["documento"],
        edad: edad,
        zona: params["zona"],
        estado: params["estado"]
      }

      resultado = Personas.registrar(persona, socket.assigns.estado.personas)

      guardar_resultado(resultado, socket, :personas, "Persona registrada correctamente")
    else
      {:error, razon} -> error(socket, razon)
    end
    |> responder()
  end

  def handle_event("actualizar_estado_persona", params, socket) do
    resultado =
      Personas.actualizar_estado(
        params["registro_id"],
        params["estado"],
        socket.assigns.estado.personas
      )

    guardar_resultado(resultado, socket, :personas, "Estado de la persona actualizado")
    |> responder()
  end

  # =========================================================
  # MENSAJES
  # =========================================================

  def handle_event("enviar_mensaje", params, socket) do
    mensaje = %{
      id: params["registro_id"],
      remitente: params["remitente"],
      destinatario: params["destinatario"],
      contenido: params["contenido"]
    }

    resultado = Mensajes.enviar(mensaje, socket.assigns.estado.mensajes)

    guardar_resultado(resultado, socket, :mensajes, "Mensaje enviado correctamente")
    |> responder()
  end

  def handle_event("actualizar_estado_mensaje", params, socket) do
    resultado =
      Mensajes.actualizar_estado(
        params["registro_id"],
        params["estado"],
        socket.assigns.estado.mensajes
      )

    guardar_resultado(resultado, socket, :mensajes, "Estado del mensaje actualizado")
    |> responder()
  end

  # =========================================================
  # MASCOTAS
  # =========================================================

  def handle_event("registrar_mascota", params, socket) do
    reporte = %{
      id: params["registro_id"],
      tipo: params["tipo"],
      especie: params["especie"],
      nombre: params["nombre"],
      caracteristicas: params["caracteristicas"],
      color: params["color"],
      tamano: params["tamano"],
      zona: params["zona"],
      contacto: params["contacto"]
    }

    resultado = Mascotas.registrar(reporte, socket.assigns.estado.mascotas)

    guardar_resultado(resultado, socket, :mascotas, "Reporte de mascota registrado")
    |> responder()
  end

  def handle_event("buscar_coincidencias", params, socket) do
    case Mascotas.posibles_coincidencias(
           params["registro_id"],
           socket.assigns.estado.mascotas
         ) do
      {:ok, coincidencias} ->
        {:noreply,
         assign(socket,
           coincidencias: coincidencias,
           mensaje:
             "Búsqueda completada. Se encontraron #{length(coincidencias)} posibles coincidencias.",
           error: nil
         )}

      {:error, razon} ->
        {:noreply, error(socket, razon)}
    end
  end

  def handle_event("confirmar_coincidencia", params, socket) do
    resultado =
      Mascotas.confirmar_coincidencia(
        params["registro_id1"],
        params["registro_id2"],
        socket.assigns.estado.mascotas
      )

    case resultado do
      {:ok, lista} ->
        guardar_coleccion(
          socket,
          :mascotas,
          lista,
          "Coincidencia confirmada. Ambos reportes quedaron resueltos."
        )
        |> assign(:coincidencias, [])
        |> responder()

      {:error, razon} ->
        error(socket, razon) |> responder()
    end
  end

  # =========================================================
  # ALBERGUES
  # =========================================================

  def handle_event("registrar_albergue", params, socket) do
    with {:ok, capacidad} <- entero(params["capacidad"]) do
      albergue = %{
        id: params["registro_id"],
        nombre: params["nombre"],
        zona: params["zona"],
        capacidad: capacidad
      }

      resultado = Albergues.registrar(albergue, socket.assigns.estado.albergues)

      guardar_resultado(resultado, socket, :albergues, "Albergue registrado correctamente")
    else
      {:error, razon} -> error(socket, razon)
    end
    |> responder()
  end

  def handle_event("movimiento_albergue", params, socket) do
    with {:ok, cantidad} <- entero(params["cantidad"]) do
      albergues = socket.assigns.estado.albergues

      resultado =
        case params["operacion"] do
          "ingresar" -> Albergues.ingresar_personas(params["registro_id"], cantidad, albergues)
          "retirar" -> Albergues.retirar_personas(params["registro_id"], cantidad, albergues)
          _ -> {:error, "Selecciona una operación válida"}
        end

      guardar_resultado(resultado, socket, :albergues, "Ocupación del albergue actualizada")
    else
      {:error, razon} -> error(socket, razon)
    end
    |> responder()
  end

  def handle_event("asociar_albergue", params, socket) do
    albergues = socket.assigns.estado.albergues

    resultado =
      case params["tipo"] do
        "recurso" ->
          Albergues.asociar_recurso(params["registro_id"], params["referencia"], albergues)

        "necesidad" ->
          Albergues.asociar_necesidad(params["registro_id"], params["referencia"], albergues)

        _ ->
          {:error, "Selecciona qué deseas asociar"}
      end

    guardar_resultado(resultado, socket, :albergues, "Asociación realizada correctamente")
    |> responder()
  end

  # =========================================================
  # PERSISTENCIA Y FUNCIONES AUXILIARES
  # =========================================================

  defp cargar_datos(socket) do
    case Gestor.iniciar() do
      {:ok, estado} ->
        assign(socket,
          estado: estado,
          resumen: Gestor.resumen(estado),
          mensaje: nil,
          error: nil
        )

      {:error, razon} ->
        assign(socket,
          estado: Gestor.estado_inicial(),
          resumen: %{},
          error: "No fue posible cargar los datos: #{razon}"
        )
    end
  end

  defp guardar_resultado({:ok, _registro, lista}, socket, coleccion, mensaje) do
    guardar_coleccion(socket, coleccion, lista, mensaje)
  end

  defp guardar_resultado({:ok, lista}, socket, coleccion, mensaje)
       when is_list(lista) do
    guardar_coleccion(socket, coleccion, lista, mensaje)
  end

  defp guardar_resultado({:error, razon}, socket, _coleccion, _mensaje) do
    error(socket, razon)
  end

  defp guardar_coleccion(socket, coleccion, lista, mensaje) do
    case Gestor.actualizar(socket.assigns.estado, coleccion, lista) do
      {:ok, nuevo_estado} ->
        assign(socket,
          estado: nuevo_estado,
          resumen: Gestor.resumen(nuevo_estado),
          mensaje: mensaje,
          error: nil
        )

      {:error, razon} ->
        error(socket, razon)
    end
  end

  defp error(socket, razon) do
    assign(socket, error: razon, mensaje: nil)
  end

  defp entero(valor) when is_binary(valor) do
    case Integer.parse(String.trim(valor)) do
      {numero, ""} -> {:ok, numero}
      _ -> {:error, "Debes ingresar un número entero válido"}
    end
  end

  defp entero(_), do: {:error, "La cantidad ingresada no es válida"}

  defp responder(socket), do: {:noreply, socket}

  defp porcentaje(albergue) do
    Float.round(Albergues.porcentaje_ocupacion(albergue), 1)
  end

  defp fecha(valor) do
    if valor, do: to_string(valor), else: "-"
  end

  defp texto(nil), do: "-"
  defp texto(valor) when is_atom(valor), do: Atom.to_string(valor)
  defp texto(valor), do: to_string(valor)

  # =========================================================
  # INTERFAZ WEB
  # =========================================================

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-base-200">
      <header class="bg-base-100 border-b border-base-300">
        <div class="max-w-7xl mx-auto px-5 py-5 flex flex-wrap justify-between items-center gap-4">
          <div>
            <h1 class="text-2xl font-bold text-primary">
              Sistema de Coordinación de Emergencias
            </h1>
            <p class="text-sm text-base-content/60 mt-1">
              Administración, atención y seguimiento de emergencias
            </p>
          </div>
          <button phx-click="actualizar" class="btn btn-primary">
            Actualizar información
          </button>
        </div>
      </header>

      <main class="max-w-7xl mx-auto px-5 py-7 space-y-6">
        <nav class="card bg-base-100 border border-base-300 shadow-sm">
          <div class="card-body p-4">
            <h2 class="font-bold mb-2">Menú principal</h2>
            <div class="grid grid-cols-2 sm:grid-cols-3 xl:grid-cols-5 gap-2">
              <button
                :for={{nombre, clave} <- @modulos}
                phx-click="cambiar_seccion"
                phx-value-seccion={clave}
                class={[
                  "btn btn-sm sm:btn-md",
                  if(@seccion == clave, do: "btn-primary", else: "btn-ghost")
                ]}
              >
                {nombre}
              </button>
            </div>
          </div>
        </nav>

        <div :if={@mensaje} class="alert alert-success">
          <span>{@mensaje}</span>
        </div>
        <div :if={@error} class="alert alert-error" role="alert">
          <span>{@error}</span>
        </div>

        <!-- RESUMEN -->

        <section :if={@seccion == :resumen} class="space-y-5">
          <div>
            <h2 class="text-2xl font-bold">Resumen general</h2>
            <p class="text-base-content/60">
              Estado actual de los registros del sistema.
            </p>
          </div>

          <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
            <div
              :for={{nombre, clave} <- Enum.drop(@modulos, 1)}
              class="card bg-base-100 border border-base-300 shadow-sm"
            >
              <div class="card-body">
                <p class="text-sm text-base-content/60">{nombre}</p>
                <p class="text-3xl font-bold text-primary">
                  {Map.get(@resumen, clave, 0)}
                </p>
                <p class="text-xs text-base-content/50">Registros almacenados</p>
              </div>
            </div>
          </div>
        </section>

        <!-- USUARIOS -->

        <section :if={@seccion == :usuarios} class="space-y-5">
          <div>
            <h2 class="text-2xl font-bold">Gestión de usuarios</h2>
            <p class="text-base-content/60">Registro y control de sesiones.</p>
          </div>

          <div class="card bg-base-100 border border-base-300 shadow-sm">
            <div class="card-body">
              <h3 class="card-title">Registrar usuario</h3>
              <form phx-submit="registrar_usuario" class="grid grid-cols-1 md:grid-cols-2 gap-3">
                <input
                  name="registro_id"
                  placeholder="Identificación"
                  class="input input-bordered w-full"
                  required
                />
                <input
                  name="nombre"
                  placeholder="Nombre completo"
                  class="input input-bordered w-full"
                  required
                />
                <input
                  name="correo"
                  type="email"
                  placeholder="Correo electrónico"
                  class="input input-bordered w-full"
                  required
                />
                <input
                  name="clave"
                  type="password"
                  minlength="6"
                  placeholder="Contraseña (mínimo 6 caracteres)"
                  class="input input-bordered w-full"
                  required
                />
                <select name="rol" class="select select-bordered w-full md:col-span-2" required>
                  <option value="">Selecciona el rol</option>
                  <option value="ciudadano">Ciudadano</option>
                  <option value="voluntario">Voluntario</option>
                  <option value="coordinador">Coordinador</option>
                  <option value="administrador">Administrador</option>
                </select>
                <button class="btn btn-primary md:col-span-2">Registrar usuario</button>
              </form>
            </div>
          </div>

          <div class="card bg-base-100 border border-base-300 shadow-sm">
            <div class="card-body">
              <h3 class="card-title">Iniciar o cerrar sesión</h3>
              <form phx-submit="iniciar_sesion_usuario" class="flex flex-col md:flex-row gap-3">
                <input
                  name="registro_id"
                  placeholder="ID del usuario"
                  class="input input-bordered flex-1"
                  required
                />
                <input
                  name="clave"
                  type="password"
                  placeholder="Contraseña"
                  class="input input-bordered flex-1"
                  required
                />
                <button class="btn btn-success">Iniciar sesión</button>
              </form>
              <form phx-submit="cerrar_sesion_usuario" class="flex flex-col sm:flex-row gap-3 mt-3">
                <input
                  name="registro_id"
                  placeholder="ID del usuario"
                  class="input input-bordered flex-1"
                  required
                />
                <button class="btn btn-outline">Cerrar sesión</button>
              </form>
            </div>
          </div>

          <div class="card bg-base-100 border border-base-300">
            <div class="card-body">
              <h3 class="card-title">Usuarios registrados</h3>
              <div class="overflow-x-auto">
                <table class="table table-zebra">
                  <thead>
                    <tr>
                      <th>ID</th><th>Nombre</th><th>Correo</th><th>Rol</th><th>Conectado</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr :for={u <- @estado.usuarios}>
                      <td>{u.id}</td><td>{u.nombre}</td><td>{u.correo}</td>
                      <td>{texto(u.rol)}</td><td>{if u.conectado, do: "Sí", else: "No"}</td>
                    </tr>
                    <tr :if={@estado.usuarios == []}>
                      <td colspan="5" class="text-center">No hay usuarios registrados.</td>
                    </tr>
                  </tbody>
                </table>
              </div>
              <p class="text-xs text-base-content/50">
                Las contraseñas se almacenan como hash y no se muestran en la tabla.
              </p>
            </div>
          </div>
        </section>

        <!-- ZONAS -->

        <section :if={@seccion == :zonas} class="space-y-5">
          <div>
            <h2 class="text-2xl font-bold">Zonas, sectores y puntos de atención</h2>
            <p class="text-base-content/60">Organización geográfica de la emergencia.</p>
          </div>

          <div class="card bg-base-100 border border-base-300">
            <div class="card-body">
              <h3 class="card-title">Registrar zona</h3>
              <form phx-submit="registrar_zona" class="grid grid-cols-1 md:grid-cols-2 gap-3">
                <input
                  name="registro_id"
                  placeholder="ID de zona"
                  class="input input-bordered w-full"
                  required
                />
                <input
                  name="nombre"
                  placeholder="Nombre de zona"
                  class="input input-bordered w-full"
                  required
                />
                <select name="nivel" class="select select-bordered w-full md:col-span-2" required>
                  <option value="">Nivel de emergencia</option>
                  <option value="critico">Crítico</option>
                  <option value="alto">Alto</option>
                  <option value="medio">Medio</option>
                  <option value="bajo">Bajo</option>
                </select>
                <button class="btn btn-primary md:col-span-2">Registrar zona</button>
              </form>
            </div>
          </div>

          <div class="card bg-base-100 border border-base-300">
            <div class="card-body">
              <h3 class="card-title">Agregar sector a una zona</h3>
              <form phx-submit="agregar_sector" class="grid grid-cols-1 md:grid-cols-3 gap-3">
                <input
                  name="zona_id"
                  placeholder="ID de zona existente"
                  class="input input-bordered w-full"
                  required
                />
                <input
                  name="registro_id"
                  placeholder="ID del sector"
                  class="input input-bordered w-full"
                  required
                />
                <input
                  name="nombre"
                  placeholder="Nombre del sector"
                  class="input input-bordered w-full"
                  required
                />
                <button class="btn btn-secondary md:col-span-3">Agregar sector</button>
              </form>
            </div>
          </div>

          <div class="card bg-base-100 border border-base-300">
            <div class="card-body">
              <h3 class="card-title">Agregar punto de atención</h3>
              <form phx-submit="agregar_punto" class="grid grid-cols-1 md:grid-cols-2 gap-3">
                <input
                  name="zona_id"
                  placeholder="ID de zona"
                  class="input input-bordered w-full"
                  required
                />
                <input
                  name="sector_id"
                  placeholder="ID de sector"
                  class="input input-bordered w-full"
                  required
                />
                <input
                  name="registro_id"
                  placeholder="ID del punto"
                  class="input input-bordered w-full"
                  required
                />
                <input
                  name="nombre"
                  placeholder="Nombre del punto"
                  class="input input-bordered w-full"
                  required
                />
                <input
                  name="direccion"
                  placeholder="Dirección"
                  class="input input-bordered w-full md:col-span-2"
                />
                <button class="btn btn-secondary md:col-span-2">Agregar punto</button>
              </form>
            </div>
          </div>

          <div class="card bg-base-100 border border-base-300">
            <div class="card-body">
              <h3 class="card-title">Estructura de zonas registradas</h3>
              <p class="text-sm text-base-content/60">
                Sectores: {Zonas.contar_sectores(@estado.zonas)} ·
                Puntos de atención: {Zonas.contar_puntos(@estado.zonas)}
              </p>
              <div :for={z <- @estado.zonas} class="border border-base-300 rounded-lg p-4 space-y-2">
                <div class="font-bold">{z.nombre} ({z.id}) — Nivel: {texto(z.nivel)}</div>
                <div :for={s <- z.sectores} class="ml-4 border-l-2 border-base-300 pl-3">
                  <p class="font-semibold">Sector: {s.nombre} ({s.id})</p>
                  <ul class="list-disc ml-5 text-sm">
                    <li :for={p <- s.puntos}>
                      {p.nombre} ({p.id}) — {p.direccion}
                    </li>
                    <li :if={s.puntos == []} class="list-none text-base-content/50">
                      Sin puntos registrados.
                    </li>
                  </ul>
                </div>
                <p :if={z.sectores == []} class="ml-4 text-sm text-base-content/50">
                  Sin sectores registrados.
                </p>
              </div>
              <p :if={@estado.zonas == []} class="text-center text-base-content/50">
                No hay zonas registradas.
              </p>
            </div>
          </div>
        </section>

        <!-- NECESIDADES -->

        <section :if={@seccion == :necesidades} class="space-y-5">
          <div>
            <h2 class="text-2xl font-bold">Gestión de necesidades</h2>
            <p class="text-base-content/60">Registro, asignación y seguimiento de solicitudes.</p>
          </div>

          <div class="card bg-base-100 border border-base-300">
            <div class="card-body">
              <h3 class="card-title">Registrar necesidad</h3>
              <form phx-submit="registrar_necesidad" class="grid grid-cols-1 md:grid-cols-2 gap-3">
                <input
                  name="registro_id"
                  placeholder="ID"
                  class="input input-bordered w-full"
                  required
                />
                <input
                  name="tipo"
                  placeholder="Tipo de necesidad"
                  class="input input-bordered w-full"
                  required
                />
                <input
                  name="descripcion"
                  placeholder="Descripción"
                  class="input input-bordered w-full"
                  required
                />
                <input
                  name="cantidad"
                  type="number"
                  min="1"
                  placeholder="Cantidad"
                  class="input input-bordered w-full"
                  required
                />
                <input name="zona" placeholder="Zona" class="input input-bordered w-full" required />
                <select name="prioridad" class="select select-bordered w-full" required>
                  <option value="">Prioridad</option><option value="critica">Crítica</option>
                  <option value="alta">Alta</option><option value="media">Media</option><option value="baja">
                    Baja
                  </option>
                </select>
                <input
                  name="responsable"
                  placeholder="Responsable (opcional)"
                  class="input input-bordered w-full md:col-span-2"
                />
                <button class="btn btn-primary md:col-span-2">Registrar necesidad</button>
              </form>
            </div>
          </div>

          <div class="card bg-base-100 border border-base-300">
            <div class="card-body">
              <h3 class="card-title">Asignar responsable</h3>
              <form phx-submit="asignar_necesidad" class="flex flex-col md:flex-row gap-3">
                <input
                  name="registro_id"
                  placeholder="ID de necesidad"
                  class="input input-bordered flex-1"
                  required
                />
                <input
                  name="responsable"
                  placeholder="Responsable"
                  class="input input-bordered flex-1"
                  required
                />
                <button class="btn btn-secondary">Asignar</button>
              </form>
            </div>
          </div>

          <div class="card bg-base-100 border border-base-300">
            <div class="card-body">
              <h3 class="card-title">Cambiar estado</h3>
              <form phx-submit="cambiar_estado_necesidad" class="flex flex-col md:flex-row gap-3">
                <input
                  name="registro_id"
                  placeholder="ID de necesidad"
                  class="input input-bordered flex-1"
                  required
                />
                <select name="estado" class="select select-bordered flex-1" required>
                  <option value="">Nuevo estado</option>
                  <option value="asignada">Asignada</option>
                  <option value="en_atencion">En atención</option>
                  <option value="atendida">Atendida</option>
                  <option value="cancelada">Cancelada</option>
                </select>
                <button class="btn btn-secondary">Actualizar estado</button>
              </form>
              <p class="text-xs text-base-content/50">
                Respeta las transiciones permitidas: pendiente → asignada → en atención → atendida. También se puede cancelar según el estado.
              </p>
            </div>
          </div>

          <div class="card bg-base-100 border border-base-300">
            <div class="card-body">
              <h3 class="card-title">Necesidades registradas</h3>
              <div class="overflow-x-auto">
                <table class="table table-zebra">
                  <thead>
                    <tr>
                      <th>ID</th><th>Tipo</th><th>Descripción</th><th>Cantidad</th><th>Zona</th><th>
                        Prioridad
                      </th><th>Responsable</th><th>Estado</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr :for={n <- @estado.necesidades}>
                      <td>{n.id}</td><td>{n.tipo}</td><td>{n.descripcion}</td><td>{n.cantidad}</td>
                      <td>{n.zona}</td><td>{texto(n.prioridad)}</td><td>
                        {n.responsable || "Sin asignar"}
                      </td><td>{texto(n.estado)}</td>
                    </tr>
                    <tr :if={@estado.necesidades == []}>
                      <td colspan="8" class="text-center">No hay necesidades registradas.</td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        </section>

        <!-- RECURSOS -->

        <section :if={@seccion == :recursos} class="space-y-5">
          <div>
            <h2 class="text-2xl font-bold">Recursos e inventario</h2>
            <p class="text-base-content/60">Existencias, entradas, salidas y transferencias.</p>
          </div>

          <div class="card bg-base-100 border border-base-300">
            <div class="card-body">
              <h3 class="card-title">Registrar recurso</h3>
              <form phx-submit="registrar_recurso" class="grid grid-cols-1 md:grid-cols-2 gap-3">
                <input
                  name="codigo"
                  placeholder="Código"
                  class="input input-bordered w-full"
                  required
                />
                <input
                  name="nombre"
                  placeholder="Nombre"
                  class="input input-bordered w-full"
                  required
                />
                <input
                  name="categoria"
                  placeholder="Categoría"
                  class="input input-bordered w-full"
                  required
                />
                <input
                  name="cantidad"
                  type="number"
                  min="1"
                  placeholder="Cantidad inicial"
                  class="input input-bordered w-full"
                  required
                />
                <input
                  name="unidad"
                  placeholder="Unidad"
                  class="input input-bordered w-full"
                  required
                />
                <input
                  name="ubicacion"
                  placeholder="Ubicación"
                  class="input input-bordered w-full"
                  required
                />
                <button class="btn btn-primary md:col-span-2">Registrar recurso</button>
              </form>
            </div>
          </div>

          <div class="card bg-base-100 border border-base-300">
            <div class="card-body">
              <h3 class="card-title">Movimiento de inventario</h3>
              <form phx-submit="movimiento_recurso" class="grid grid-cols-1 md:grid-cols-2 gap-3">
                <input
                  name="codigo"
                  placeholder="Código del recurso"
                  class="input input-bordered w-full"
                  required
                />
                <input
                  name="cantidad"
                  type="number"
                  min="1"
                  placeholder="Cantidad"
                  class="input input-bordered w-full"
                  required
                />
                <select name="operacion" class="select select-bordered w-full" required>
                  <option value="">Movimiento</option><option value="entrada">Entrada</option>
                  <option value="salida">Salida</option><option value="transferencia">
                    Transferencia
                  </option>
                </select>
                <input
                  name="destino"
                  placeholder="Destino (para transferencia)"
                  class="input input-bordered w-full"
                />
                <button class="btn btn-secondary md:col-span-2">Registrar movimiento</button>
              </form>
            </div>
          </div>

          <div class="card bg-base-100 border border-base-300">
            <div class="card-body">
              <h3 class="card-title">Inventario disponible</h3>
              <div class="overflow-x-auto">
                <table class="table table-zebra">
                  <thead>
                    <tr>
                      <th>Código</th><th>Nombre</th><th>Categoría</th><th>Cantidad</th><th>Unidad</th><th>
                        Ubicación
                      </th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr :for={r <- @estado.recursos}>
                      <td>{r.codigo}</td><td>{r.nombre}</td><td>{r.categoria}</td>
                      <td class="font-bold">{r.cantidad}</td><td>{r.unidad}</td><td>{r.ubicacion}</td>
                    </tr>
                    <tr :if={@estado.recursos == []}>
                      <td colspan="6" class="text-center">No hay recursos registrados.</td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>
          </div>

          <div class="card bg-base-100 border border-base-300">
            <div class="card-body">
              <h3 class="card-title">Historial de movimientos</h3>
              <div :for={r <- @estado.recursos} class="border-b border-base-300 pb-3">
                <p class="font-semibold">{r.nombre} ({r.codigo})</p>
                <div :for={m <- r.historial} class="text-sm text-base-content/70 ml-3">
                  {texto(m.tipo)} — Cantidad: {m.cantidad}
                  <span :if={Map.has_key?(m, :ubicacion)}> — Ubicación: {m.ubicacion}</span>
                  <span :if={Map.has_key?(m, :origen)}> — Origen: {m.origen}; destino: {m.destino}</span>
                </div>
              </div>
            </div>
          </div>
        </section>

        <!-- PERSONAS -->

        <section :if={@seccion == :personas} class="space-y-5">
          <div>
            <h2 class="text-2xl font-bold">Personas afectadas</h2>
            <p class="text-base-content/60">Registro y seguimiento de personas.</p>
          </div>

          <div class="card bg-base-100 border border-base-300">
            <div class="card-body">
              <h3 class="card-title">Registrar persona</h3>
              <form phx-submit="registrar_persona" class="grid grid-cols-1 md:grid-cols-2 gap-3">
                <input
                  name="registro_id"
                  placeholder="ID de registro"
                  class="input input-bordered w-full"
                  required
                />
                <input
                  name="nombre"
                  placeholder="Nombre completo"
                  class="input input-bordered w-full"
                  required
                />
                <input
                  name="documento"
                  placeholder="Documento"
                  class="input input-bordered w-full"
                  required
                />
                <input
                  name="edad"
                  type="number"
                  min="0"
                  placeholder="Edad"
                  class="input input-bordered w-full"
                  required
                />
                <input name="zona" placeholder="Zona" class="input input-bordered w-full" required />
                <select name="estado" class="select select-bordered w-full" required>
                  <option value="sin_confirmar">Sin confirmar</option>
                  <option value="desaparecida">Desaparecida</option>
                  <option value="localizada">Localizada</option>
                  <option value="hospitalizada">Hospitalizada</option>
                  <option value="fallecida">Fallecida</option>
                </select>
                <button class="btn btn-primary md:col-span-2">Registrar persona</button>
              </form>
            </div>
          </div>

          <div class="card bg-base-100 border border-base-300">
            <div class="card-body">
              <h3 class="card-title">Actualizar estado de una persona</h3>
              <form phx-submit="actualizar_estado_persona" class="flex flex-col md:flex-row gap-3">
                <input
                  name="registro_id"
                  placeholder="ID de persona"
                  class="input input-bordered flex-1"
                  required
                />
                <select name="estado" class="select select-bordered flex-1" required>
                  <option value="">Nuevo estado</option>
                  <option value="sin_confirmar">Sin confirmar</option>
                  <option value="desaparecida">Desaparecida</option>
                  <option value="localizada">Localizada</option>
                  <option value="hospitalizada">Hospitalizada</option>
                  <option value="fallecida">Fallecida</option>
                </select>
                <button class="btn btn-secondary">Actualizar</button>
              </form>
            </div>
          </div>

          <div class="card bg-base-100 border border-base-300">
            <div class="card-body">
              <h3 class="card-title">Personas registradas</h3>
              <div class="overflow-x-auto">
                <table class="table table-zebra">
                  <thead>
                    <tr>
                      <th>ID</th><th>Nombre</th><th>Documento</th><th>Edad</th><th>Zona</th><th>
                        Estado
                      </th><th>Historial</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr :for={p <- @estado.personas}>
                      <td>{p.id}</td><td>{p.nombre}</td><td>{p.documento}</td><td>{p.edad}</td>
                      <td>{p.zona}</td><td>{texto(p.estado)}</td><td>
                        {length(p.historial)} cambios
                      </td>
                    </tr>
                    <tr :if={@estado.personas == []}>
                      <td colspan="7" class="text-center">No hay personas registradas.</td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        </section>

        <!-- MENSAJES -->

        <section :if={@seccion == :mensajes} class="space-y-5">
          <div>
            <h2 class="text-2xl font-bold">Comunicación familiar</h2>
            <p class="text-base-content/60">Envío y seguimiento de mensajes.</p>
          </div>

          <div class="card bg-base-100 border border-base-300">
            <div class="card-body">
              <h3 class="card-title">Enviar mensaje</h3>
              <form phx-submit="enviar_mensaje" class="grid grid-cols-1 md:grid-cols-2 gap-3">
                <input
                  name="registro_id"
                  placeholder="ID del mensaje"
                  class="input input-bordered w-full"
                  required
                />
                <input
                  name="remitente"
                  placeholder="ID o nombre del remitente"
                  class="input input-bordered w-full"
                  required
                />
                <input
                  name="destinatario"
                  placeholder="ID o nombre del destinatario"
                  class="input input-bordered w-full"
                  required
                />
                <textarea
                  name="contenido"
                  placeholder="Contenido del mensaje"
                  class="textarea textarea-bordered w-full md:col-span-2"
                  required
                ></textarea>
                <button class="btn btn-primary md:col-span-2">Enviar mensaje</button>
              </form>
            </div>
          </div>

          <div class="card bg-base-100 border border-base-300">
            <div class="card-body">
              <h3 class="card-title">Actualizar estado del mensaje</h3>
              <form phx-submit="actualizar_estado_mensaje" class="flex flex-col md:flex-row gap-3">
                <input
                  name="registro_id"
                  placeholder="ID del mensaje"
                  class="input input-bordered flex-1"
                  required
                />
                <select name="estado" class="select select-bordered flex-1" required>
                  <option value="">Nuevo estado</option>
                  <option value="entregado">Entregado</option>
                  <option value="leido">Leído</option>
                  <option value="fallido">Fallido</option>
                </select>
                <button class="btn btn-secondary">Actualizar estado</button>
              </form>
              <p class="text-xs text-base-content/50">
                Transiciones válidas: enviado → entregado o fallido; entregado → leído.
              </p>
            </div>
          </div>

          <div class="card bg-base-100 border border-base-300">
            <div class="card-body">
              <h3 class="card-title">Mensajes registrados</h3>
              <div class="overflow-x-auto">
                <table class="table table-zebra">
                  <thead>
                    <tr>
                      <th>ID</th><th>Remitente</th><th>Destinatario</th><th>Contenido</th><th>
                        Fecha
                      </th><th>Estado</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr :for={m <- @estado.mensajes}>
                      <td>{m.id}</td><td>{m.remitente}</td><td>{m.destinatario}</td>
                      <td class="whitespace-normal min-w-48">{m.contenido}</td>
                      <td>{fecha(m.fecha)}</td><td>{texto(m.estado)}</td>
                    </tr>
                    <tr :if={@estado.mensajes == []}>
                      <td colspan="6" class="text-center">No hay mensajes registrados.</td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        </section>

        <!-- MASCOTAS -->

        <section :if={@seccion == :mascotas} class="space-y-5">
          <div>
            <h2 class="text-2xl font-bold">Mascotas perdidas y encontradas</h2>
            <p class="text-base-content/60">Registro de reportes y búsqueda de coincidencias.</p>
          </div>

          <div class="card bg-base-100 border border-base-300">
            <div class="card-body">
              <h3 class="card-title">Registrar reporte de mascota</h3>
              <form phx-submit="registrar_mascota" class="grid grid-cols-1 md:grid-cols-2 gap-3">
                <input
                  name="registro_id"
                  placeholder="ID del reporte"
                  class="input input-bordered w-full"
                  required
                />
                <select name="tipo" class="select select-bordered w-full" required>
                  <option value="">Tipo de reporte</option>
                  <option value="perdida">Mascota perdida</option>
                  <option value="encontrada">Mascota encontrada</option>
                </select>
                <input
                  name="especie"
                  placeholder="Especie"
                  class="input input-bordered w-full"
                  required
                />
                <input
                  name="nombre"
                  placeholder="Nombre (si se conoce)"
                  class="input input-bordered w-full"
                />
                <input name="color" placeholder="Color" class="input input-bordered w-full" required />
                <input
                  name="tamano"
                  placeholder="Tamaño"
                  class="input input-bordered w-full"
                  required
                />
                <input
                  name="zona"
                  placeholder="Zona donde se perdió o encontró"
                  class="input input-bordered w-full"
                  required
                />
                <input
                  name="contacto"
                  placeholder="Contacto"
                  class="input input-bordered w-full"
                  required
                />
                <textarea
                  name="caracteristicas"
                  placeholder="Características particulares"
                  class="textarea textarea-bordered w-full md:col-span-2"
                ></textarea>
                <button class="btn btn-primary md:col-span-2">Registrar reporte</button>
              </form>
            </div>
          </div>

          <div class="card bg-base-100 border border-base-300">
            <div class="card-body">
              <h3 class="card-title">Buscar posibles coincidencias</h3>
              <form phx-submit="buscar_coincidencias" class="flex flex-col sm:flex-row gap-3">
                <input
                  name="registro_id"
                  placeholder="ID del reporte"
                  class="input input-bordered flex-1"
                  required
                />
                <button class="btn btn-secondary">Buscar coincidencias</button>
              </form>

              <div :if={@coincidencias != []} class="space-y-3 mt-4">
                <h4 class="font-semibold">Resultados de similitud</h4>
                <div :for={c <- @coincidencias} class="border border-base-300 rounded-lg p-3">
                  <p class="font-semibold">{c.reporte.id} — {texto(c.reporte.tipo)}</p>
                  <p class="text-sm">
                    Especie: {c.reporte.especie} · Color: {c.reporte.color} · Zona: {c.reporte.zona}
                  </p>
                  <p class="text-sm font-bold text-primary">Similitud: {c.puntaje}%</p>
                </div>
                <p class="text-xs text-base-content/50">
                  Para confirmar una coincidencia, utiliza los dos ID en el formulario siguiente.
                </p>
              </div>
            </div>
          </div>

          <div class="card bg-base-100 border border-base-300">
            <div class="card-body">
              <h3 class="card-title">Confirmar coincidencia</h3>
              <form phx-submit="confirmar_coincidencia" class="grid grid-cols-1 md:grid-cols-2 gap-3">
                <input
                  name="id1"
                  placeholder="ID del reporte perdido"
                  class="input input-bordered w-full"
                  required
                />
                <input
                  name="id2"
                  placeholder="ID del reporte encontrado"
                  class="input input-bordered w-full"
                  required
                />
                <button class="btn btn-success md:col-span-2">Confirmar y resolver ambos reportes</button>
              </form>
            </div>
          </div>

          <div class="card bg-base-100 border border-base-300">
            <div class="card-body">
              <h3 class="card-title">Reportes registrados</h3>
              <div class="overflow-x-auto">
                <table class="table table-zebra">
                  <thead>
                    <tr>
                      <th>ID</th><th>Tipo</th><th>Especie</th><th>Nombre</th><th>Color</th><th>
                        Tamaño
                      </th><th>Zona</th><th>Contacto</th><th>Estado</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr :for={m <- @estado.mascotas}>
                      <td>{m.id}</td><td>{texto(m.tipo)}</td><td>{m.especie}</td><td>{m.nombre}</td>
                      <td>{m.color}</td><td>{m.tamano}</td><td>{m.zona}</td><td>{m.contacto}</td><td>
                        {texto(m.estado)}
                      </td>
                    </tr>
                    <tr :if={@estado.mascotas == []}>
                      <td colspan="9" class="text-center">No hay reportes registrados.</td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        </section>

        <!-- ALBERGUES -->

        <section :if={@seccion == :albergues} class="space-y-5">
          <div>
            <h2 class="text-2xl font-bold">Gestión de albergues</h2>
            <p class="text-base-content/60">Capacidad, ocupación y asociaciones.</p>
          </div>

          <div class="card bg-base-100 border border-base-300">
            <div class="card-body">
              <h3 class="card-title">Registrar albergue</h3>
              <form phx-submit="registrar_albergue" class="grid grid-cols-1 md:grid-cols-2 gap-3">
                <input
                  name="registro_id"
                  placeholder="ID del albergue"
                  class="input input-bordered w-full"
                  required
                />
                <input
                  name="nombre"
                  placeholder="Nombre"
                  class="input input-bordered w-full"
                  required
                />
                <input name="zona" placeholder="Zona" class="input input-bordered w-full" required />
                <input
                  name="capacidad"
                  type="number"
                  min="1"
                  placeholder="Capacidad máxima"
                  class="input input-bordered w-full"
                  required
                />
                <button class="btn btn-primary md:col-span-2">Registrar albergue</button>
              </form>
            </div>
          </div>

          <div class="card bg-base-100 border border-base-300">
            <div class="card-body">
              <h3 class="card-title">Ingreso o retiro de personas</h3>
              <form phx-submit="movimiento_albergue" class="grid grid-cols-1 md:grid-cols-3 gap-3">
                <input
                  name="registro_id"
                  placeholder="ID del albergue"
                  class="input input-bordered w-full"
                  required
                />
                <input
                  name="cantidad"
                  type="number"
                  min="1"
                  placeholder="Cantidad de personas"
                  class="input input-bordered w-full"
                  required
                />
                <select name="operacion" class="select select-bordered w-full" required>
                  <option value="">Operación</option><option value="ingresar">Ingresar</option><option value="retirar">
                    Retirar
                  </option>
                </select>
                <button class="btn btn-secondary md:col-span-3">Registrar movimiento</button>
              </form>
            </div>
          </div>

          <div class="card bg-base-100 border border-base-300">
            <div class="card-body">
              <h3 class="card-title">Asociar recursos o necesidades</h3>
              <form phx-submit="asociar_albergue" class="grid grid-cols-1 md:grid-cols-3 gap-3">
                <input
                  name="registro_id"
                  placeholder="ID del albergue"
                  class="input input-bordered w-full"
                  required
                />
                <select name="tipo" class="select select-bordered w-full" required>
                  <option value="">Tipo de asociación</option><option value="recurso">Recurso</option><option value="necesidad">
                    Necesidad
                  </option>
                </select>
                <input
                  name="referencia"
                  placeholder="Código o ID relacionado"
                  class="input input-bordered w-full"
                  required
                />
                <button class="btn btn-secondary md:col-span-3">Asociar</button>
              </form>
            </div>
          </div>

          <div class="card bg-base-100 border border-base-300">
            <div class="card-body">
              <h3 class="card-title">Albergues registrados</h3>
              <div class="overflow-x-auto">
                <table class="table table-zebra">
                  <thead>
                    <tr>
                      <th>ID</th><th>Nombre</th><th>Zona</th><th>Ocupación</th><th>Capacidad</th><th>
                        Disponibles
                      </th><th>Ocupación %</th><th>Recursos</th><th>Necesidades</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr :for={a <- @estado.albergues}>
                      <td>{a.id}</td><td>{a.nombre}</td><td>{a.zona}</td>
                      <td>{a.ocupacion}</td><td>{a.capacidad}</td>
                      <td>{a.capacidad - a.ocupacion}</td><td>{porcentaje(a)}%</td>
                      <td>{Enum.join(a.recursos, ", ")}</td><td>{Enum.join(a.necesidades, ", ")}</td>
                    </tr>
                    <tr :if={@estado.albergues == []}>
                      <td colspan="9" class="text-center">No hay albergues registrados.</td>
                    </tr>
                  </tbody>
                </table>
              </div>
              <div :if={@estado.albergues != []} class="mt-3 text-sm">
                <strong>Mayor ocupación:</strong>
                <%= case Albergues.mayor_ocupacion(@estado.albergues) do %>
                  <% {:ok, mayor} -> %>
                    {mayor.nombre} — {porcentaje(mayor)}%
                  <% {:error, _} -> %>
                    Sin datos
                <% end %>
              </div>
            </div>
          </div>
        </section>

        <footer class="text-center text-sm text-base-content/50 py-5">
          Sistema de Coordinación y Gestión de Emergencias
        </footer>
      </main>
    </div>
    """
  end
end
