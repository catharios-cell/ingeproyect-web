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

-- IMPORTANTE (a futuro): estas políticas son abiertas a propósito para este prototipo,
-- igual que en el resto de las tablas. Antes de manejar datos reales de clientes conviene
-- reemplazarlas por políticas basadas en Supabase Auth (ver notas en clientes/trabajadores).
