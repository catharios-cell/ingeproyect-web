-- Esquema Supabase para la intranet de Grupo Ingeproyect SpA
-- Ejecutar en: Dashboard Supabase > SQL Editor > New query

create extension if not exists "pgcrypto";

create table if not exists clientes (
  id uuid primary key default gen_random_uuid(),
  nombre text not null,
  rut text,
  direccion text,
  telefono text,
  contacto text,
  usuario text unique,
  clave text,
  created_at timestamptz not null default now()
);
-- Nota de seguridad: "clave" queda en texto plano por simplicidad de este prototipo.
-- Antes de usar en producción real, conviene mover el login de clientes a Supabase Auth
-- (con hash de contraseña) en vez de guardar la clave en la tabla.

create table if not exists historico_trabajos (
  id uuid primary key default gen_random_uuid(),
  cliente_id uuid not null references clientes(id) on delete cascade,
  descripcion text not null,
  fecha date,
  monto numeric,
  estado text default 'completado',
  created_at timestamptz not null default now()
);

create table if not exists cotizaciones (
  id uuid primary key default gen_random_uuid(),
  cliente_id uuid references clientes(id) on delete set null,
  numero text,
  fecha date not null default current_date,
  tipo_mantencion text,
  equipo text,
  ubicacion text,
  detalle text,
  materiales jsonb default '[]'::jsonb,
  horas_estimadas numeric,
  costo_mano_obra_estimado numeric,
  monto numeric,
  validez_dias integer,
  condiciones_pago text,
  estado text default 'pendiente',
  created_at timestamptz not null default now()
);

create table if not exists trabajadores (
  id uuid primary key default gen_random_uuid(),
  nombre text not null,
  usuario text unique,
  clave text,
  rol text not null default 'tecnico', -- 'tecnico' o 'validador'
  created_at timestamptz not null default now()
);
-- Nota de seguridad: igual que en "clientes", la clave queda en texto plano por
-- simplicidad de este prototipo. Antes de producción real, mover a Supabase Auth.

create table if not exists reportes (
  id uuid primary key default gen_random_uuid(),
  cliente_id uuid references clientes(id) on delete set null,
  trabajo_id uuid references historico_trabajos(id) on delete set null,
  numero text,
  titulo text not null,
  tipo_servicio text,
  equipo text,
  marca_modelo text,
  ubicacion text,
  tecnico text,
  fecha_inicio date,
  fecha date not null default current_date,
  contenido text,
  mediciones text,
  recomendaciones text,
  materiales jsonb default '[]'::jsonb,
  horas numeric,
  costo_mano_obra numeric,
  valor_total numeric,
  estado_facturacion text default 'pendiente',
  numero_factura text,
  estado_final text default 'aprobado',
  conformidad text,
  trabajador_id uuid references trabajadores(id) on delete set null,
  estado_validacion text not null default 'pendiente', -- 'pendiente' | 'validado' | 'rechazado'
  validado_por text,
  fecha_validacion date,
  fotos jsonb default '[]'::jsonb, -- [{ tipo: 'antes'|'despues', url, nombre }]
  video_url text,
  created_at timestamptz not null default now()
);
-- El cliente solo debe poder ver, en su portal, los reportes con estado_validacion = 'validado'.

create table if not exists inventario (
  id uuid primary key default gen_random_uuid(),
  nombre text not null unique,
  categoria text default 'general', -- 'bombas' | 'calderas' | 'general'
  unidad text default 'unidad',
  stock numeric not null default 0,
  stock_minimo numeric default 0,
  costo_referencia numeric,
  created_at timestamptz not null default now()
);

-- Catálogo inicial de productos típicos de mantención de bombas y calderas.
-- Se puede seguir agregando productos desde la Intranet (pestaña Inventario).
insert into inventario (nombre, categoria, unidad, stock, stock_minimo, costo_referencia) values
  ('Sello mecánico estándar', 'bombas', 'unidad', 12, 4, 18000),
  ('Sello mecánico doble', 'bombas', 'unidad', 6, 2, 35000),
  ('Empaquetadura de grafito', 'bombas', 'metro', 25, 10, 6000),
  ('Empaquetadura de teflón', 'bombas', 'metro', 20, 8, 5500),
  ('Rodamiento SKF 6205', 'bombas', 'unidad', 8, 4, 15000),
  ('Rodamiento SKF 6206', 'bombas', 'unidad', 6, 3, 17000),
  ('Rodamiento de rodillos cónicos', 'bombas', 'unidad', 4, 2, 28000),
  ('Correa trapezoidal A-38', 'bombas', 'unidad', 10, 3, 9000),
  ('Correa trapezoidal B-50', 'bombas', 'unidad', 8, 3, 11000),
  ('Acople flexible tipo araña', 'bombas', 'unidad', 6, 2, 25000),
  ('Acople rígido', 'bombas', 'unidad', 5, 2, 30000),
  ('Impulsor de bomba centrífuga', 'bombas', 'unidad', 3, 2, 65000),
  ('Eje de bomba', 'bombas', 'unidad', 2, 1, 85000),
  ('Camisa de eje', 'bombas', 'unidad', 5, 2, 22000),
  ('Válvula de retención 2"', 'bombas', 'unidad', 5, 2, 32000),
  ('Válvula de retención 4"', 'bombas', 'unidad', 3, 1, 48000),
  ('Válvula de compuerta 2"', 'bombas', 'unidad', 5, 2, 28000),
  ('Válvula de compuerta 4"', 'bombas', 'unidad', 3, 1, 42000),
  ('Válvula de bola 1"', 'bombas', 'unidad', 10, 3, 12000),
  ('Válvula de mariposa 3"', 'bombas', 'unidad', 4, 2, 38000),
  ('Manómetro de presión (bombas)', 'bombas', 'unidad', 8, 3, 14000),
  ('Prensaestopas', 'bombas', 'unidad', 10, 4, 8000),
  ('Kit de o-rings surtido', 'bombas', 'unidad', 15, 5, 6000),
  ('Base antivibración', 'bombas', 'unidad', 6, 2, 20000),
  ('Electrodo de soldadura 6013', 'calderas', 'kg', 20, 5, 4500),
  ('Electrodo de soldadura 7018', 'calderas', 'kg', 15, 5, 5200),
  ('Empaquetadura para mirilla de caldera', 'calderas', 'unidad', 8, 3, 12000),
  ('Quemador boquilla diésel', 'calderas', 'unidad', 4, 2, 40000),
  ('Quemador boquilla gas', 'calderas', 'unidad', 3, 2, 42000),
  ('Termocupla tipo K', 'calderas', 'unidad', 6, 3, 15000),
  ('Termocupla tipo J', 'calderas', 'unidad', 4, 2, 15000),
  ('Presostato de caldera', 'calderas', 'unidad', 3, 2, 35000),
  ('Válvula de seguridad 1/2"', 'calderas', 'unidad', 4, 2, 45000),
  ('Válvula de seguridad 1"', 'calderas', 'unidad', 3, 1, 58000),
  ('Tubo de caldera 2"', 'calderas', 'metro', 15, 5, 22000),
  ('Tubo de caldera 3"', 'calderas', 'metro', 10, 4, 28000),
  ('Cemento refractario', 'calderas', 'kg', 30, 10, 3500),
  ('Ladrillo refractario', 'calderas', 'unidad', 40, 15, 2500),
  ('Fibra cerámica aislante', 'calderas', 'metro', 12, 5, 9000),
  ('Control de nivel de agua', 'calderas', 'unidad', 3, 1, 55000),
  ('Bomba de alimentación de agua', 'calderas', 'unidad', 2, 1, 120000),
  ('Visor de llama', 'calderas', 'unidad', 4, 2, 18000),
  ('Transformador de encendido', 'calderas', 'unidad', 3, 1, 45000),
  ('Filtro de gasoil para quemador', 'calderas', 'unidad', 10, 4, 6000),
  ('Manómetro de caldera 0-16 bar', 'calderas', 'unidad', 6, 2, 16000),
  ('Purgador / trampa de vapor termodinámica', 'calderas', 'unidad', 5, 2, 26000),
  ('Sensor de temperatura PT100', 'general', 'unidad', 6, 2, 20000),
  ('Variador de frecuencia', 'general', 'unidad', 2, 1, 180000),
  ('Contactor eléctrico', 'general', 'unidad', 8, 3, 15000),
  ('Relé térmico', 'general', 'unidad', 8, 3, 12000),
  ('Fusible industrial', 'general', 'unidad', 20, 8, 2500),
  ('Cable eléctrico 2.5mm (rollo 100m)', 'general', 'unidad', 5, 2, 45000),
  ('Terminal eléctrico surtido', 'general', 'unidad', 50, 15, 300),
  ('Presostato diferencial', 'general', 'unidad', 4, 2, 32000),
  ('Aceite lubricante ISO 68', 'general', 'litro', 40, 10, 4000),
  ('Aceite lubricante ISO 32', 'general', 'litro', 30, 10, 4200),
  ('Grasa multipropósito', 'general', 'kg', 15, 5, 5000),
  ('Grasa para altas temperaturas', 'general', 'kg', 10, 3, 8000),
  ('Filtro de aceite', 'general', 'unidad', 12, 4, 8000),
  ('Filtro de aire', 'general', 'unidad', 12, 4, 7000),
  ('Pernos y tuercas surtidos', 'general', 'unidad', 100, 20, 500),
  ('Cinta de teflón', 'general', 'unidad', 30, 10, 1200),
  ('Silicona alta temperatura', 'general', 'unidad', 15, 5, 3500),
  ('Guantes de seguridad (par)', 'general', 'unidad', 25, 10, 4000)
on conflict (nombre) do nothing;

create table if not exists movimientos_inventario (
  id uuid primary key default gen_random_uuid(),
  inventario_id uuid references inventario(id) on delete set null,
  reporte_id uuid references reportes(id) on delete set null,
  tipo text not null default 'salida', -- 'entrada' | 'salida' | 'ajuste'
  cantidad numeric not null,
  nota text,
  created_at timestamptz not null default now()
);
-- Cuando se guarda un Reporte, cada material que coincide por nombre con un producto de
-- "inventario" genera automáticamente un movimiento tipo 'salida' y descuenta el stock.

-- Bucket de Storage para las fotos/video que suben los técnicos desde la app de terreno.
-- Se deja público para simplificar este prototipo (mismo criterio que las políticas "allow all" de abajo).
insert into storage.buckets (id, name, public)
values ('reportes-fotos', 'reportes-fotos', true)
on conflict (id) do nothing;

drop policy if exists "allow all reportes-fotos" on storage.objects;
create policy "allow all reportes-fotos" on storage.objects for all
  using (bucket_id = 'reportes-fotos') with check (bucket_id = 'reportes-fotos');

-- RLS: habilitado, con política abierta por ahora (herramienta interna sin login).
-- Se puede restringir más adelante agregando autenticación de administradores.
alter table clientes enable row level security;
alter table historico_trabajos enable row level security;
alter table cotizaciones enable row level security;
alter table reportes enable row level security;
alter table trabajadores enable row level security;
alter table inventario enable row level security;
alter table movimientos_inventario enable row level security;

drop policy if exists "allow all clientes" on clientes;
create policy "allow all clientes" on clientes for all using (true) with check (true);

drop policy if exists "allow all historico" on historico_trabajos;
create policy "allow all historico" on historico_trabajos for all using (true) with check (true);

drop policy if exists "allow all cotizaciones" on cotizaciones;
create policy "allow all cotizaciones" on cotizaciones for all using (true) with check (true);

drop policy if exists "allow all reportes" on reportes;
create policy "allow all reportes" on reportes for all using (true) with check (true);

drop policy if exists "allow all trabajadores" on trabajadores;
create policy "allow all trabajadores" on trabajadores for all using (true) with check (true);

drop policy if exists "allow all inventario" on inventario;
create policy "allow all inventario" on inventario for all using (true) with check (true);

drop policy if exists "allow all movimientos_inventario" on movimientos_inventario;
create policy "allow all movimientos_inventario" on movimientos_inventario for all using (true) with check (true);

-- IMPORTANTE (a futuro): estas políticas son abiertas a propósito para este prototipo,
-- igual que en el resto de las tablas. Antes de manejar datos reales de clientes conviene
-- reemplazarlas por políticas basadas en Supabase Auth (ver notas en clientes/trabajadores).
