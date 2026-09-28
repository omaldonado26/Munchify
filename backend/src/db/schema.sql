-- =====================================================================
-- Munchify - Plataforma de cupones y recompensas por interacción digital
-- Esquema de base de datos (MySQL 8+ / MariaDB 10.6+)
-- =====================================================================

CREATE DATABASE IF NOT EXISTS munchify CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE munchify;

SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS notificaciones;
DROP TABLE IF EXISTS movimientos_puntos;
DROP TABLE IF EXISTS cupones;
DROP TABLE IF EXISTS evidencias;
DROP TABLE IF EXISTS recompensas;
DROP TABLE IF EXISTS campanas;
DROP TABLE IF EXISTS comercios;
DROP TABLE IF EXISTS categorias;
DROP TABLE IF EXISTS usuarios;
SET FOREIGN_KEY_CHECKS = 1;

-- ---------------------------------------------------------------------
-- Usuarios (clientes, comercios y administradores)
-- ---------------------------------------------------------------------
CREATE TABLE usuarios (
  id            INT AUTO_INCREMENT PRIMARY KEY,
  nombre        VARCHAR(120) NOT NULL,
  email         VARCHAR(160) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  rol           ENUM('cliente','comercio','admin') NOT NULL DEFAULT 'cliente',
  telefono      VARCHAR(30) NULL,
  usuario_instagram VARCHAR(80) NULL,
  puntos        INT NOT NULL DEFAULT 0,
  fcm_token     VARCHAR(255) NULL,
  activo        TINYINT(1) NOT NULL DEFAULT 1,
  creado_en     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- Categorías de promociones / comercios
-- ---------------------------------------------------------------------
CREATE TABLE categorias (
  id     INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(60) NOT NULL UNIQUE,
  icono  VARCHAR(40) NULL
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- Comercios (perfil de negocio ligado a un usuario con rol 'comercio')
-- ---------------------------------------------------------------------
CREATE TABLE comercios (
  id           INT AUTO_INCREMENT PRIMARY KEY,
  usuario_id   INT NOT NULL UNIQUE,
  nombre       VARCHAR(120) NOT NULL,
  descripcion  VARCHAR(500) NULL,
  direccion    VARCHAR(255) NULL,
  telefono     VARCHAR(30) NULL,
  instagram    VARCHAR(80) NULL,
  categoria_id INT NULL,
  logo_url     VARCHAR(255) NULL,
  creado_en    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_comercio_usuario   FOREIGN KEY (usuario_id)   REFERENCES usuarios(id) ON DELETE CASCADE,
  CONSTRAINT fk_comercio_categoria FOREIGN KEY (categoria_id) REFERENCES categorias(id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- Campañas / promociones
-- ---------------------------------------------------------------------
CREATE TABLE campanas (
  id                   INT AUTO_INCREMENT PRIMARY KEY,
  comercio_id          INT NOT NULL,
  categoria_id         INT NULL,
  titulo               VARCHAR(140) NOT NULL,
  descripcion          VARCHAR(1000) NULL,
  beneficio            VARCHAR(255) NOT NULL,           -- ej. "2x1 en hamburguesas"
  condiciones          VARCHAR(1000) NULL,              -- ej. "Sube una historia mencionando a @negocio"
  tipo_accion          ENUM('historia','publicacion','resena','comentario','seguir','otro') NOT NULL DEFAULT 'historia',
  red_social           ENUM('instagram','facebook','tiktok','google','x','otra') NOT NULL DEFAULT 'instagram',
  tipo_evidencia       ENUM('captura','enlace','cualquiera') NOT NULL DEFAULT 'cualquiera',
  validacion_automatica TINYINT(1) NOT NULL DEFAULT 0, -- 1 = aprueba evidencia sin revisión manual
  fecha_inicio         DATE NOT NULL,
  fecha_fin            DATE NOT NULL,
  vigencia_cupon_dias  INT NOT NULL DEFAULT 7,          -- días que dura el cupón tras emitirse
  cantidad_disponible  INT NOT NULL DEFAULT 100,        -- cupones máximos de la campaña
  cupones_emitidos     INT NOT NULL DEFAULT 0,
  puntos_otorgados     INT NOT NULL DEFAULT 10,         -- puntos al validar la acción
  imagen_url           VARCHAR(255) NULL,
  estado               ENUM('activa','pausada','finalizada') NOT NULL DEFAULT 'activa',
  creado_en            DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_campana_comercio  FOREIGN KEY (comercio_id)  REFERENCES comercios(id) ON DELETE CASCADE,
  CONSTRAINT fk_campana_categoria FOREIGN KEY (categoria_id) REFERENCES categorias(id) ON DELETE SET NULL,
  CONSTRAINT chk_fechas CHECK (fecha_fin >= fecha_inicio),
  INDEX idx_campana_estado (estado, fecha_fin)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- Evidencias de acciones en redes sociales
-- Un usuario participa una sola vez por campaña.
-- ---------------------------------------------------------------------
CREATE TABLE evidencias (
  id             INT AUTO_INCREMENT PRIMARY KEY,
  campana_id     INT NOT NULL,
  usuario_id     INT NOT NULL,
  enlace         VARCHAR(500) NULL,
  archivo        VARCHAR(255) NULL,       -- ruta de la captura subida
  comentario     VARCHAR(500) NULL,
  estado         ENUM('pendiente','aprobada','rechazada') NOT NULL DEFAULT 'pendiente',
  motivo_rechazo VARCHAR(255) NULL,
  revisado_por   INT NULL,
  creado_en      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  revisado_en    DATETIME NULL,
  CONSTRAINT fk_evid_campana FOREIGN KEY (campana_id)   REFERENCES campanas(id) ON DELETE CASCADE,
  CONSTRAINT fk_evid_usuario FOREIGN KEY (usuario_id)   REFERENCES usuarios(id) ON DELETE CASCADE,
  CONSTRAINT fk_evid_revisor FOREIGN KEY (revisado_por) REFERENCES usuarios(id) ON DELETE SET NULL,
  UNIQUE KEY uq_evid_usuario_campana (campana_id, usuario_id),
  INDEX idx_evid_estado (estado)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- Recompensas canjeables con puntos
-- ---------------------------------------------------------------------
CREATE TABLE recompensas (
  id            INT AUTO_INCREMENT PRIMARY KEY,
  comercio_id   INT NOT NULL,
  nombre        VARCHAR(120) NOT NULL,
  descripcion   VARCHAR(500) NULL,
  costo_puntos  INT NOT NULL,
  stock         INT NOT NULL DEFAULT 50,
  vigencia_dias INT NOT NULL DEFAULT 15,
  activa        TINYINT(1) NOT NULL DEFAULT 1,
  creado_en     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_recomp_comercio FOREIGN KEY (comercio_id) REFERENCES comercios(id) ON DELETE CASCADE,
  CONSTRAINT chk_costo CHECK (costo_puntos > 0)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- Cupones digitales (por campaña o por canje de recompensa)
-- ---------------------------------------------------------------------
CREATE TABLE cupones (
  id                INT AUTO_INCREMENT PRIMARY KEY,
  codigo            VARCHAR(20) NOT NULL UNIQUE,   -- código único que va en el QR
  origen            ENUM('campana','recompensa') NOT NULL DEFAULT 'campana',
  campana_id        INT NULL,
  recompensa_id     INT NULL,
  evidencia_id      INT NULL UNIQUE,
  comercio_id       INT NOT NULL,
  usuario_id        INT NOT NULL,
  beneficio         VARCHAR(255) NOT NULL,
  estado            ENUM('activo','canjeado','vencido','anulado') NOT NULL DEFAULT 'activo',
  fecha_emision     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  fecha_vencimiento DATETIME NOT NULL,
  fecha_canje       DATETIME NULL,
  canjeado_por      INT NULL,
  CONSTRAINT fk_cupon_campana    FOREIGN KEY (campana_id)    REFERENCES campanas(id)    ON DELETE SET NULL,
  CONSTRAINT fk_cupon_recompensa FOREIGN KEY (recompensa_id) REFERENCES recompensas(id) ON DELETE SET NULL,
  CONSTRAINT fk_cupon_evidencia  FOREIGN KEY (evidencia_id)  REFERENCES evidencias(id)  ON DELETE SET NULL,
  CONSTRAINT fk_cupon_comercio   FOREIGN KEY (comercio_id)   REFERENCES comercios(id)   ON DELETE CASCADE,
  CONSTRAINT fk_cupon_usuario    FOREIGN KEY (usuario_id)    REFERENCES usuarios(id)    ON DELETE CASCADE,
  CONSTRAINT fk_cupon_canjeador  FOREIGN KEY (canjeado_por)  REFERENCES usuarios(id)    ON DELETE SET NULL,
  INDEX idx_cupon_usuario (usuario_id, estado),
  INDEX idx_cupon_comercio (comercio_id, estado)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- Movimientos de puntos (bitácora para trazabilidad)
-- ---------------------------------------------------------------------
CREATE TABLE movimientos_puntos (
  id         INT AUTO_INCREMENT PRIMARY KEY,
  usuario_id INT NOT NULL,
  puntos     INT NOT NULL,                  -- positivo = gana, negativo = gasta
  concepto   VARCHAR(160) NOT NULL,
  cupon_id   INT NULL,
  creado_en  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_mov_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE,
  CONSTRAINT fk_mov_cupon   FOREIGN KEY (cupon_id)   REFERENCES cupones(id)  ON DELETE SET NULL
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- Notificaciones in-app (y opcionalmente push vía Firebase)
-- ---------------------------------------------------------------------
CREATE TABLE notificaciones (
  id         INT AUTO_INCREMENT PRIMARY KEY,
  usuario_id INT NOT NULL,
  titulo     VARCHAR(120) NOT NULL,
  mensaje    VARCHAR(500) NOT NULL,
  tipo       ENUM('promocion','evidencia','cupon','puntos','sistema') NOT NULL DEFAULT 'sistema',
  leida      TINYINT(1) NOT NULL DEFAULT 0,
  creado_en  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_notif_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE,
  INDEX idx_notif_usuario (usuario_id, leida)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- Categorías base
-- ---------------------------------------------------------------------
INSERT INTO categorias (nombre, icono) VALUES
 ('Restaurantes','restaurant'),
 ('Cafeterías','local_cafe'),
 ('Ropa','checkroom'),
 ('Calzado','hiking'),
 ('Belleza','spa'),
 ('Entretenimiento','celebration');
