-- erd-app · ejemplo sintético de 150 tablas
-- Generado por tools/generate-example.mjs; no editar a mano.
-- MySQL 8.0.16+ / InnoDB / utf8mb4. No contiene datos reales ni INSERT.
-- 150 tablas · 1549 columnas · 356 relaciones.

CREATE DATABASE IF NOT EXISTS `erd_demo_150` CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE `erd_demo_150`;

SET NAMES utf8mb4;
SET time_zone = '+00:00';
SET FOREIGN_KEY_CHECKS = 0;

-- ============================================================
-- Módulo: Núcleo y seguridad
-- ============================================================

CREATE TABLE `core_empresas` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `descripcion` VARCHAR(255) NULL,
  `ruc` VARCHAR(20) NOT NULL UNIQUE,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `core_usuarios` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `descripcion` VARCHAR(255) NULL,
  `correo` VARCHAR(160) NOT NULL UNIQUE,
  `telefono` VARCHAR(40) NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_core_usuarios_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `core_roles` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `descripcion` VARCHAR(255) NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_core_roles_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `core_permisos` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `descripcion` VARCHAR(255) NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_core_permisos_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `core_usuario_roles` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `usuario_id` BIGINT UNSIGNED NOT NULL,
  `rol_id` BIGINT UNSIGNED NOT NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `descripcion` VARCHAR(255) NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_core_usuario_roles_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_core_usuario_roles_usuario_id` FOREIGN KEY (`usuario_id`) REFERENCES `core_usuarios` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_core_usuario_roles_rol_id` FOREIGN KEY (`rol_id`) REFERENCES `core_roles` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `core_monedas` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `descripcion` VARCHAR(255) NULL,
  `simbolo` CHAR(3) NOT NULL,
  `decimales` TINYINT NOT NULL DEFAULT 2,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_core_monedas_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `core_paises` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `descripcion` VARCHAR(255) NULL,
  `codigo_iso` CHAR(2) NOT NULL UNIQUE,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_core_paises_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `core_ciudades` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `pais_id` BIGINT UNSIGNED NOT NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `descripcion` VARCHAR(255) NULL,
  `codigo_postal` VARCHAR(12) NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_core_ciudades_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_core_ciudades_pais_id` FOREIGN KEY (`pais_id`) REFERENCES `core_paises` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `core_estados` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `pais_id` BIGINT UNSIGNED NOT NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `descripcion` VARCHAR(255) NULL,
  `ambito` VARCHAR(20) NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_core_estados_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_core_estados_pais_id` FOREIGN KEY (`pais_id`) REFERENCES `core_paises` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `core_configuracion` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `descripcion` VARCHAR(255) NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_core_configuracion_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `core_auditoria` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `descripcion` VARCHAR(255) NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_core_auditoria_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `core_notificaciones` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `descripcion` VARCHAR(255) NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_core_notificaciones_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `core_archivos` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `descripcion` VARCHAR(255) NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_core_archivos_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `core_categorias` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `parent_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `descripcion` VARCHAR(255) NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_core_categorias_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_core_categorias_parent` FOREIGN KEY (`parent_id`) REFERENCES `core_categorias` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `core_etiquetas` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `descripcion` VARCHAR(255) NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_core_etiquetas_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- ============================================================
-- Módulo: CRM
-- ============================================================

CREATE TABLE `crm_clientes` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `correo` VARCHAR(160) NULL,
  `telefono` VARCHAR(40) NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_crm_clientes_tenant` (`tenant_id`, `id`),
  CONSTRAINT `fk_crm_clientes_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `crm_contactos` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `client_id` BIGINT UNSIGNED NOT NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `correo` VARCHAR(160) NULL,
  `telefono` VARCHAR(40) NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_crm_contactos_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_crm_contactos_tenant_client` FOREIGN KEY (`tenant_id`, `client_id`) REFERENCES `crm_clientes` (`tenant_id`, `id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `crm_oportunidades` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `client_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `correo` VARCHAR(160) NULL,
  `telefono` VARCHAR(40) NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_crm_oportunidades_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_crm_oportunidades_client_id` FOREIGN KEY (`client_id`) REFERENCES `crm_clientes` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `crm_actividades` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `client_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `correo` VARCHAR(160) NULL,
  `telefono` VARCHAR(40) NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_crm_actividades_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_crm_actividades_client_id` FOREIGN KEY (`client_id`) REFERENCES `crm_clientes` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `crm_campanas` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `client_id` BIGINT UNSIGNED NULL,
  `usuario_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `correo` VARCHAR(160) NULL,
  `telefono` VARCHAR(40) NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_crm_campanas_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_crm_campanas_client_id` FOREIGN KEY (`client_id`) REFERENCES `crm_clientes` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_crm_campanas_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `core_usuarios` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `crm_segmentos` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `client_id` BIGINT UNSIGNED NULL,
  `parent_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `correo` VARCHAR(160) NULL,
  `telefono` VARCHAR(40) NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_crm_segmentos_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_crm_segmentos_client_id` FOREIGN KEY (`client_id`) REFERENCES `crm_clientes` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_crm_segmentos_parent` FOREIGN KEY (`parent_id`) REFERENCES `crm_segmentos` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `crm_interacciones` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `client_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `correo` VARCHAR(160) NULL,
  `telefono` VARCHAR(40) NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_crm_interacciones_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_crm_interacciones_client_id` FOREIGN KEY (`client_id`) REFERENCES `crm_clientes` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `crm_prospectos` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `client_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `correo` VARCHAR(160) NULL,
  `telefono` VARCHAR(40) NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_crm_prospectos_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_crm_prospectos_client_id` FOREIGN KEY (`client_id`) REFERENCES `crm_clientes` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `crm_cotizaciones` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `client_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `correo` VARCHAR(160) NULL,
  `telefono` VARCHAR(40) NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_crm_cotizaciones_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_crm_cotizaciones_client_id` FOREIGN KEY (`client_id`) REFERENCES `crm_clientes` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `crm_seguimientos` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `client_id` BIGINT UNSIGNED NULL,
  `usuario_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `correo` VARCHAR(160) NULL,
  `telefono` VARCHAR(40) NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_crm_seguimientos_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_crm_seguimientos_client_id` FOREIGN KEY (`client_id`) REFERENCES `crm_clientes` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_crm_seguimientos_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `core_usuarios` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `crm_consentimientos` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `client_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `correo` VARCHAR(160) NULL,
  `telefono` VARCHAR(40) NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_crm_consentimientos_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_crm_consentimientos_client_id` FOREIGN KEY (`client_id`) REFERENCES `crm_clientes` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `crm_direcciones` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `client_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `correo` VARCHAR(160) NULL,
  `telefono` VARCHAR(40) NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_crm_direcciones_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_crm_direcciones_client_id` FOREIGN KEY (`client_id`) REFERENCES `crm_clientes` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `crm_telefonos` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `client_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `correo` VARCHAR(160) NULL,
  `telefono` VARCHAR(40) NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_crm_telefonos_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_crm_telefonos_client_id` FOREIGN KEY (`client_id`) REFERENCES `crm_clientes` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `crm_correos` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `client_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `correo` VARCHAR(160) NULL,
  `telefono` VARCHAR(40) NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_crm_correos_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_crm_correos_client_id` FOREIGN KEY (`client_id`) REFERENCES `crm_clientes` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `crm_encuestas` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `client_id` BIGINT UNSIGNED NULL,
  `usuario_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `correo` VARCHAR(160) NULL,
  `telefono` VARCHAR(40) NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_crm_encuestas_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_crm_encuestas_client_id` FOREIGN KEY (`client_id`) REFERENCES `crm_clientes` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_crm_encuestas_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `core_usuarios` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- ============================================================
-- Módulo: Ventas
-- ============================================================

CREATE TABLE `ventas_pedidos` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `cliente_id` BIGINT UNSIGNED NULL,
  `moneda_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `monto` DECIMAL(14,2) NOT NULL DEFAULT 0,
  `fecha` DATE NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_ventas_pedidos_tenant` (`tenant_id`, `id`),
  CONSTRAINT `fk_ventas_pedidos_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_ventas_pedidos_cliente` FOREIGN KEY (`cliente_id`) REFERENCES `crm_clientes` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_ventas_pedidos_moneda` FOREIGN KEY (`moneda_id`) REFERENCES `core_monedas` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `ventas_pedido_lineas` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `pedido_id` BIGINT UNSIGNED NOT NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `monto` DECIMAL(14,2) NOT NULL DEFAULT 0,
  `fecha` DATE NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_ventas_pedido_lineas_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_ventas_pedido_lineas_tenant_pedido` FOREIGN KEY (`tenant_id`, `pedido_id`) REFERENCES `ventas_pedidos` (`tenant_id`, `id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `ventas_facturas` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `pedido_id` BIGINT UNSIGNED NOT NULL UNIQUE,
  `cliente_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `monto` DECIMAL(14,2) NOT NULL DEFAULT 0,
  `fecha` DATE NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_ventas_facturas_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_ventas_facturas_pedido_id` FOREIGN KEY (`pedido_id`) REFERENCES `ventas_pedidos` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_ventas_facturas_cliente` FOREIGN KEY (`cliente_id`) REFERENCES `crm_clientes` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `ventas_factura_lineas` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `pedido_id` BIGINT UNSIGNED NULL,
  `cliente_id` BIGINT UNSIGNED NULL,
  `moneda_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `monto` DECIMAL(14,2) NOT NULL DEFAULT 0,
  `fecha` DATE NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_ventas_factura_lineas_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_ventas_factura_lineas_pedido_id` FOREIGN KEY (`pedido_id`) REFERENCES `ventas_pedidos` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_ventas_factura_lineas_cliente` FOREIGN KEY (`cliente_id`) REFERENCES `crm_clientes` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_ventas_factura_lineas_moneda` FOREIGN KEY (`moneda_id`) REFERENCES `core_monedas` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `ventas_pagos` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `pedido_id` BIGINT UNSIGNED NULL,
  `cliente_id` BIGINT UNSIGNED NULL,
  `usuario_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `monto` DECIMAL(14,2) NOT NULL DEFAULT 0,
  `fecha` DATE NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_ventas_pagos_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_ventas_pagos_pedido_id` FOREIGN KEY (`pedido_id`) REFERENCES `ventas_pedidos` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_ventas_pagos_cliente` FOREIGN KEY (`cliente_id`) REFERENCES `crm_clientes` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_ventas_pagos_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `core_usuarios` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `ventas_devoluciones` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `pedido_id` BIGINT UNSIGNED NULL,
  `cliente_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `monto` DECIMAL(14,2) NOT NULL DEFAULT 0,
  `fecha` DATE NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_ventas_devoluciones_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_ventas_devoluciones_pedido_id` FOREIGN KEY (`pedido_id`) REFERENCES `ventas_pedidos` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_ventas_devoluciones_cliente` FOREIGN KEY (`cliente_id`) REFERENCES `crm_clientes` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `ventas_descuentos` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `pedido_id` BIGINT UNSIGNED NULL,
  `cliente_id` BIGINT UNSIGNED NULL,
  `moneda_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `monto` DECIMAL(14,2) NOT NULL DEFAULT 0,
  `fecha` DATE NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_ventas_descuentos_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_ventas_descuentos_pedido_id` FOREIGN KEY (`pedido_id`) REFERENCES `ventas_pedidos` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_ventas_descuentos_cliente` FOREIGN KEY (`cliente_id`) REFERENCES `crm_clientes` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_ventas_descuentos_moneda` FOREIGN KEY (`moneda_id`) REFERENCES `core_monedas` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `ventas_vendedores` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `pedido_id` BIGINT UNSIGNED NULL,
  `cliente_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `monto` DECIMAL(14,2) NOT NULL DEFAULT 0,
  `fecha` DATE NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_ventas_vendedores_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_ventas_vendedores_pedido_id` FOREIGN KEY (`pedido_id`) REFERENCES `ventas_pedidos` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_ventas_vendedores_cliente` FOREIGN KEY (`cliente_id`) REFERENCES `crm_clientes` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `ventas_metas` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `pedido_id` BIGINT UNSIGNED NULL,
  `cliente_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `monto` DECIMAL(14,2) NOT NULL DEFAULT 0,
  `fecha` DATE NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_ventas_metas_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_ventas_metas_pedido_id` FOREIGN KEY (`pedido_id`) REFERENCES `ventas_pedidos` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_ventas_metas_cliente` FOREIGN KEY (`cliente_id`) REFERENCES `crm_clientes` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `ventas_comisiones` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `pedido_id` BIGINT UNSIGNED NULL,
  `cliente_id` BIGINT UNSIGNED NULL,
  `usuario_id` BIGINT UNSIGNED NULL,
  `moneda_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `monto` DECIMAL(14,2) NOT NULL DEFAULT 0,
  `fecha` DATE NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_ventas_comisiones_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_ventas_comisiones_pedido_id` FOREIGN KEY (`pedido_id`) REFERENCES `ventas_pedidos` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_ventas_comisiones_cliente` FOREIGN KEY (`cliente_id`) REFERENCES `crm_clientes` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_ventas_comisiones_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `core_usuarios` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_ventas_comisiones_moneda` FOREIGN KEY (`moneda_id`) REFERENCES `core_monedas` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `ventas_suscripciones` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `pedido_id` BIGINT UNSIGNED NULL,
  `cliente_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `monto` DECIMAL(14,2) NOT NULL DEFAULT 0,
  `fecha` DATE NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_ventas_suscripciones_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_ventas_suscripciones_pedido_id` FOREIGN KEY (`pedido_id`) REFERENCES `ventas_pedidos` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_ventas_suscripciones_cliente` FOREIGN KEY (`cliente_id`) REFERENCES `crm_clientes` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `ventas_renovaciones` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `pedido_id` BIGINT UNSIGNED NULL,
  `cliente_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `monto` DECIMAL(14,2) NOT NULL DEFAULT 0,
  `fecha` DATE NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_ventas_renovaciones_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_ventas_renovaciones_pedido_id` FOREIGN KEY (`pedido_id`) REFERENCES `ventas_pedidos` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_ventas_renovaciones_cliente` FOREIGN KEY (`cliente_id`) REFERENCES `crm_clientes` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `ventas_contratos` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `pedido_id` BIGINT UNSIGNED NULL,
  `cliente_id` BIGINT UNSIGNED NULL,
  `moneda_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `monto` DECIMAL(14,2) NOT NULL DEFAULT 0,
  `fecha` DATE NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_ventas_contratos_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_ventas_contratos_pedido_id` FOREIGN KEY (`pedido_id`) REFERENCES `ventas_pedidos` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_ventas_contratos_cliente` FOREIGN KEY (`cliente_id`) REFERENCES `crm_clientes` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_ventas_contratos_moneda` FOREIGN KEY (`moneda_id`) REFERENCES `core_monedas` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `ventas_ofertas` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `pedido_id` BIGINT UNSIGNED NULL,
  `cliente_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `monto` DECIMAL(14,2) NOT NULL DEFAULT 0,
  `fecha` DATE NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_ventas_ofertas_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_ventas_ofertas_pedido_id` FOREIGN KEY (`pedido_id`) REFERENCES `ventas_pedidos` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_ventas_ofertas_cliente` FOREIGN KEY (`cliente_id`) REFERENCES `crm_clientes` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `ventas_listas_precios` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `pedido_id` BIGINT UNSIGNED NULL,
  `cliente_id` BIGINT UNSIGNED NULL,
  `usuario_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `monto` DECIMAL(14,2) NOT NULL DEFAULT 0,
  `fecha` DATE NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_ventas_listas_precios_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_ventas_listas_precios_pedido_id` FOREIGN KEY (`pedido_id`) REFERENCES `ventas_pedidos` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_ventas_listas_precios_cliente` FOREIGN KEY (`cliente_id`) REFERENCES `crm_clientes` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_ventas_listas_precios_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `core_usuarios` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- ============================================================
-- Módulo: Compras
-- ============================================================

CREATE TABLE `compras_ordenes` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `proveedor_id` BIGINT UNSIGNED NULL,
  `moneda_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `monto` DECIMAL(14,2) NOT NULL DEFAULT 0,
  `fecha` DATE NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_compras_ordenes_tenant` (`tenant_id`, `id`),
  CONSTRAINT `fk_compras_ordenes_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_compras_ordenes_proveedor` FOREIGN KEY (`proveedor_id`) REFERENCES `compras_proveedores` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_compras_ordenes_moneda` FOREIGN KEY (`moneda_id`) REFERENCES `core_monedas` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `compras_orden_lineas` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `orden_id` BIGINT UNSIGNED NOT NULL,
  `proveedor_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `monto` DECIMAL(14,2) NOT NULL DEFAULT 0,
  `fecha` DATE NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_compras_orden_lineas_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_compras_orden_lineas_tenant_orden` FOREIGN KEY (`tenant_id`, `orden_id`) REFERENCES `compras_ordenes` (`tenant_id`, `id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_compras_orden_lineas_proveedor` FOREIGN KEY (`proveedor_id`) REFERENCES `compras_proveedores` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `compras_proveedores` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `orden_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `monto` DECIMAL(14,2) NOT NULL DEFAULT 0,
  `fecha` DATE NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_compras_proveedores_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_compras_proveedores_orden_id` FOREIGN KEY (`orden_id`) REFERENCES `compras_ordenes` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `compras_solicitudes` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `orden_id` BIGINT UNSIGNED NULL,
  `proveedor_id` BIGINT UNSIGNED NULL,
  `moneda_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `monto` DECIMAL(14,2) NOT NULL DEFAULT 0,
  `fecha` DATE NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_compras_solicitudes_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_compras_solicitudes_orden_id` FOREIGN KEY (`orden_id`) REFERENCES `compras_ordenes` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_compras_solicitudes_proveedor` FOREIGN KEY (`proveedor_id`) REFERENCES `compras_proveedores` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_compras_solicitudes_moneda` FOREIGN KEY (`moneda_id`) REFERENCES `core_monedas` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `compras_recepciones` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `orden_id` BIGINT UNSIGNED NOT NULL UNIQUE,
  `proveedor_id` BIGINT UNSIGNED NULL,
  `usuario_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `monto` DECIMAL(14,2) NOT NULL DEFAULT 0,
  `fecha` DATE NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_compras_recepciones_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_compras_recepciones_orden_id` FOREIGN KEY (`orden_id`) REFERENCES `compras_ordenes` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_compras_recepciones_proveedor` FOREIGN KEY (`proveedor_id`) REFERENCES `compras_proveedores` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_compras_recepciones_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `core_usuarios` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `compras_facturas` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `orden_id` BIGINT UNSIGNED NULL,
  `proveedor_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `monto` DECIMAL(14,2) NOT NULL DEFAULT 0,
  `fecha` DATE NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_compras_facturas_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_compras_facturas_orden_id` FOREIGN KEY (`orden_id`) REFERENCES `compras_ordenes` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_compras_facturas_proveedor` FOREIGN KEY (`proveedor_id`) REFERENCES `compras_proveedores` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `compras_pagos` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `orden_id` BIGINT UNSIGNED NULL,
  `proveedor_id` BIGINT UNSIGNED NULL,
  `moneda_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `monto` DECIMAL(14,2) NOT NULL DEFAULT 0,
  `fecha` DATE NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_compras_pagos_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_compras_pagos_orden_id` FOREIGN KEY (`orden_id`) REFERENCES `compras_ordenes` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_compras_pagos_proveedor` FOREIGN KEY (`proveedor_id`) REFERENCES `compras_proveedores` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_compras_pagos_moneda` FOREIGN KEY (`moneda_id`) REFERENCES `core_monedas` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `compras_contratos` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `orden_id` BIGINT UNSIGNED NULL,
  `proveedor_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `monto` DECIMAL(14,2) NOT NULL DEFAULT 0,
  `fecha` DATE NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_compras_contratos_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_compras_contratos_orden_id` FOREIGN KEY (`orden_id`) REFERENCES `compras_ordenes` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_compras_contratos_proveedor` FOREIGN KEY (`proveedor_id`) REFERENCES `compras_proveedores` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `compras_evaluaciones` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `orden_id` BIGINT UNSIGNED NULL,
  `proveedor_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `monto` DECIMAL(14,2) NOT NULL DEFAULT 0,
  `fecha` DATE NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_compras_evaluaciones_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_compras_evaluaciones_orden_id` FOREIGN KEY (`orden_id`) REFERENCES `compras_ordenes` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_compras_evaluaciones_proveedor` FOREIGN KEY (`proveedor_id`) REFERENCES `compras_proveedores` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `compras_categorias` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `orden_id` BIGINT UNSIGNED NULL,
  `parent_id` BIGINT UNSIGNED NULL,
  `proveedor_id` BIGINT UNSIGNED NULL,
  `usuario_id` BIGINT UNSIGNED NULL,
  `moneda_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `monto` DECIMAL(14,2) NOT NULL DEFAULT 0,
  `fecha` DATE NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_compras_categorias_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_compras_categorias_orden_id` FOREIGN KEY (`orden_id`) REFERENCES `compras_ordenes` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_compras_categorias_parent` FOREIGN KEY (`parent_id`) REFERENCES `compras_categorias` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_compras_categorias_proveedor` FOREIGN KEY (`proveedor_id`) REFERENCES `compras_proveedores` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_compras_categorias_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `core_usuarios` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_compras_categorias_moneda` FOREIGN KEY (`moneda_id`) REFERENCES `core_monedas` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `compras_requisiciones` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `orden_id` BIGINT UNSIGNED NULL,
  `proveedor_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `monto` DECIMAL(14,2) NOT NULL DEFAULT 0,
  `fecha` DATE NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_compras_requisiciones_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_compras_requisiciones_orden_id` FOREIGN KEY (`orden_id`) REFERENCES `compras_ordenes` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_compras_requisiciones_proveedor` FOREIGN KEY (`proveedor_id`) REFERENCES `compras_proveedores` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `compras_comparativas` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `orden_id` BIGINT UNSIGNED NULL,
  `proveedor_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `monto` DECIMAL(14,2) NOT NULL DEFAULT 0,
  `fecha` DATE NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_compras_comparativas_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_compras_comparativas_orden_id` FOREIGN KEY (`orden_id`) REFERENCES `compras_ordenes` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_compras_comparativas_proveedor` FOREIGN KEY (`proveedor_id`) REFERENCES `compras_proveedores` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `compras_incidencias` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `orden_id` BIGINT UNSIGNED NULL,
  `proveedor_id` BIGINT UNSIGNED NULL,
  `moneda_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `monto` DECIMAL(14,2) NOT NULL DEFAULT 0,
  `fecha` DATE NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_compras_incidencias_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_compras_incidencias_orden_id` FOREIGN KEY (`orden_id`) REFERENCES `compras_ordenes` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_compras_incidencias_proveedor` FOREIGN KEY (`proveedor_id`) REFERENCES `compras_proveedores` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_compras_incidencias_moneda` FOREIGN KEY (`moneda_id`) REFERENCES `core_monedas` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `compras_devoluciones` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `orden_id` BIGINT UNSIGNED NULL,
  `proveedor_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `monto` DECIMAL(14,2) NOT NULL DEFAULT 0,
  `fecha` DATE NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_compras_devoluciones_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_compras_devoluciones_orden_id` FOREIGN KEY (`orden_id`) REFERENCES `compras_ordenes` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_compras_devoluciones_proveedor` FOREIGN KEY (`proveedor_id`) REFERENCES `compras_proveedores` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `compras_presupuestos` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `orden_id` BIGINT UNSIGNED NULL,
  `proveedor_id` BIGINT UNSIGNED NULL,
  `usuario_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `monto` DECIMAL(14,2) NOT NULL DEFAULT 0,
  `fecha` DATE NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_compras_presupuestos_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_compras_presupuestos_orden_id` FOREIGN KEY (`orden_id`) REFERENCES `compras_ordenes` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_compras_presupuestos_proveedor` FOREIGN KEY (`proveedor_id`) REFERENCES `compras_proveedores` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_compras_presupuestos_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `core_usuarios` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- ============================================================
-- Módulo: Inventario
-- ============================================================

CREATE TABLE `inventario_productos` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `cantidad` INT NOT NULL DEFAULT 0,
  `referencia` VARCHAR(60) NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_inventario_productos_tenant` (`tenant_id`, `id`),
  CONSTRAINT `fk_inventario_productos_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `inventario_variantes` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `producto_id` BIGINT UNSIGNED NOT NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `cantidad` INT NOT NULL DEFAULT 0,
  `referencia` VARCHAR(60) NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_inventario_variantes_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_inventario_variantes_tenant_producto` FOREIGN KEY (`tenant_id`, `producto_id`) REFERENCES `inventario_productos` (`tenant_id`, `id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `inventario_categorias` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `producto_id` BIGINT UNSIGNED NULL,
  `parent_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `cantidad` INT NOT NULL DEFAULT 0,
  `referencia` VARCHAR(60) NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_inventario_categorias_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_inventario_categorias_producto_id` FOREIGN KEY (`producto_id`) REFERENCES `inventario_productos` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_inventario_categorias_parent` FOREIGN KEY (`parent_id`) REFERENCES `inventario_categorias` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `inventario_almacenes` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `producto_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `cantidad` INT NOT NULL DEFAULT 0,
  `referencia` VARCHAR(60) NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_inventario_almacenes_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_inventario_almacenes_producto_id` FOREIGN KEY (`producto_id`) REFERENCES `inventario_productos` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `inventario_ubicaciones` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `producto_id` BIGINT UNSIGNED NULL,
  `usuario_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `cantidad` INT NOT NULL DEFAULT 0,
  `referencia` VARCHAR(60) NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_inventario_ubicaciones_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_inventario_ubicaciones_producto_id` FOREIGN KEY (`producto_id`) REFERENCES `inventario_productos` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_inventario_ubicaciones_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `core_usuarios` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `inventario_stock` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `producto_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `cantidad` INT NOT NULL DEFAULT 0,
  `referencia` VARCHAR(60) NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_inventario_stock_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_inventario_stock_producto_id` FOREIGN KEY (`producto_id`) REFERENCES `inventario_productos` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `inventario_movimientos` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `producto_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `cantidad` INT NOT NULL DEFAULT 0,
  `referencia` VARCHAR(60) NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_inventario_movimientos_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_inventario_movimientos_producto_id` FOREIGN KEY (`producto_id`) REFERENCES `inventario_productos` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `inventario_lotes` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `producto_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `cantidad` INT NOT NULL DEFAULT 0,
  `referencia` VARCHAR(60) NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_inventario_lotes_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_inventario_lotes_producto_id` FOREIGN KEY (`producto_id`) REFERENCES `inventario_productos` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `inventario_series` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `producto_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `cantidad` INT NOT NULL DEFAULT 0,
  `referencia` VARCHAR(60) NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_inventario_series_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_inventario_series_producto_id` FOREIGN KEY (`producto_id`) REFERENCES `inventario_productos` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `inventario_transferencias` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `producto_id` BIGINT UNSIGNED NULL,
  `usuario_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `cantidad` INT NOT NULL DEFAULT 0,
  `referencia` VARCHAR(60) NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_inventario_transferencias_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_inventario_transferencias_producto_id` FOREIGN KEY (`producto_id`) REFERENCES `inventario_productos` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_inventario_transferencias_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `core_usuarios` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `inventario_ajustes` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `producto_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `cantidad` INT NOT NULL DEFAULT 0,
  `referencia` VARCHAR(60) NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_inventario_ajustes_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_inventario_ajustes_producto_id` FOREIGN KEY (`producto_id`) REFERENCES `inventario_productos` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `inventario_conteos` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `producto_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `cantidad` INT NOT NULL DEFAULT 0,
  `referencia` VARCHAR(60) NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_inventario_conteos_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_inventario_conteos_producto_id` FOREIGN KEY (`producto_id`) REFERENCES `inventario_productos` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `inventario_kits` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `producto_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `cantidad` INT NOT NULL DEFAULT 0,
  `referencia` VARCHAR(60) NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_inventario_kits_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_inventario_kits_producto_id` FOREIGN KEY (`producto_id`) REFERENCES `inventario_productos` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `inventario_precios` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `producto_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `cantidad` INT NOT NULL DEFAULT 0,
  `referencia` VARCHAR(60) NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_inventario_precios_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_inventario_precios_producto_id` FOREIGN KEY (`producto_id`) REFERENCES `inventario_productos` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `inventario_reordenes` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `producto_id` BIGINT UNSIGNED NULL,
  `usuario_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `cantidad` INT NOT NULL DEFAULT 0,
  `referencia` VARCHAR(60) NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_inventario_reordenes_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_inventario_reordenes_producto_id` FOREIGN KEY (`producto_id`) REFERENCES `inventario_productos` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_inventario_reordenes_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `core_usuarios` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- ============================================================
-- Módulo: Finanzas
-- ============================================================

CREATE TABLE `finanzas_asientos` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `moneda_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `monto` DECIMAL(14,2) NOT NULL DEFAULT 0,
  `fecha` DATE NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_finanzas_asientos_tenant` (`tenant_id`, `id`),
  CONSTRAINT `fk_finanzas_asientos_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_finanzas_asientos_moneda` FOREIGN KEY (`moneda_id`) REFERENCES `core_monedas` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `finanzas_asiento_lineas` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `asiento_id` BIGINT UNSIGNED NOT NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `monto` DECIMAL(14,2) NOT NULL DEFAULT 0,
  `fecha` DATE NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_finanzas_asiento_lineas_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_finanzas_asiento_lineas_tenant_asiento` FOREIGN KEY (`tenant_id`, `asiento_id`) REFERENCES `finanzas_asientos` (`tenant_id`, `id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `finanzas_cuentas` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `asiento_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `monto` DECIMAL(14,2) NOT NULL DEFAULT 0,
  `fecha` DATE NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_finanzas_cuentas_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_finanzas_cuentas_asiento_id` FOREIGN KEY (`asiento_id`) REFERENCES `finanzas_asientos` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `finanzas_movimientos` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `asiento_id` BIGINT UNSIGNED NULL,
  `moneda_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `monto` DECIMAL(14,2) NOT NULL DEFAULT 0,
  `fecha` DATE NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_finanzas_movimientos_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_finanzas_movimientos_asiento_id` FOREIGN KEY (`asiento_id`) REFERENCES `finanzas_asientos` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_finanzas_movimientos_moneda` FOREIGN KEY (`moneda_id`) REFERENCES `core_monedas` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `finanzas_presupuestos` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `asiento_id` BIGINT UNSIGNED NULL,
  `usuario_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `monto` DECIMAL(14,2) NOT NULL DEFAULT 0,
  `fecha` DATE NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_finanzas_presupuestos_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_finanzas_presupuestos_asiento_id` FOREIGN KEY (`asiento_id`) REFERENCES `finanzas_asientos` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_finanzas_presupuestos_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `core_usuarios` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `finanzas_centros_costo` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `asiento_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `monto` DECIMAL(14,2) NOT NULL DEFAULT 0,
  `fecha` DATE NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_finanzas_centros_costo_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_finanzas_centros_costo_asiento_id` FOREIGN KEY (`asiento_id`) REFERENCES `finanzas_asientos` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `finanzas_impuestos` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `asiento_id` BIGINT UNSIGNED NULL,
  `moneda_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `monto` DECIMAL(14,2) NOT NULL DEFAULT 0,
  `fecha` DATE NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_finanzas_impuestos_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_finanzas_impuestos_asiento_id` FOREIGN KEY (`asiento_id`) REFERENCES `finanzas_asientos` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_finanzas_impuestos_moneda` FOREIGN KEY (`moneda_id`) REFERENCES `core_monedas` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `finanzas_tipos_cambio` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `asiento_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `monto` DECIMAL(14,2) NOT NULL DEFAULT 0,
  `fecha` DATE NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_finanzas_tipos_cambio_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_finanzas_tipos_cambio_asiento_id` FOREIGN KEY (`asiento_id`) REFERENCES `finanzas_asientos` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `finanzas_conciliaciones` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `asiento_id` BIGINT UNSIGNED NULL UNIQUE,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `monto` DECIMAL(14,2) NOT NULL DEFAULT 0,
  `fecha` DATE NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_finanzas_conciliaciones_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_finanzas_conciliaciones_asiento_id` FOREIGN KEY (`asiento_id`) REFERENCES `finanzas_asientos` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `finanzas_cobros` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `asiento_id` BIGINT UNSIGNED NULL,
  `usuario_id` BIGINT UNSIGNED NULL,
  `moneda_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `monto` DECIMAL(14,2) NOT NULL DEFAULT 0,
  `fecha` DATE NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_finanzas_cobros_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_finanzas_cobros_asiento_id` FOREIGN KEY (`asiento_id`) REFERENCES `finanzas_asientos` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_finanzas_cobros_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `core_usuarios` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_finanzas_cobros_moneda` FOREIGN KEY (`moneda_id`) REFERENCES `core_monedas` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `finanzas_pagos` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `asiento_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `monto` DECIMAL(14,2) NOT NULL DEFAULT 0,
  `fecha` DATE NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_finanzas_pagos_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_finanzas_pagos_asiento_id` FOREIGN KEY (`asiento_id`) REFERENCES `finanzas_asientos` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `finanzas_periodos` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `asiento_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `monto` DECIMAL(14,2) NOT NULL DEFAULT 0,
  `fecha` DATE NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_finanzas_periodos_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_finanzas_periodos_asiento_id` FOREIGN KEY (`asiento_id`) REFERENCES `finanzas_asientos` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `finanzas_activos` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `asiento_id` BIGINT UNSIGNED NULL,
  `moneda_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `monto` DECIMAL(14,2) NOT NULL DEFAULT 0,
  `fecha` DATE NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_finanzas_activos_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_finanzas_activos_asiento_id` FOREIGN KEY (`asiento_id`) REFERENCES `finanzas_asientos` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_finanzas_activos_moneda` FOREIGN KEY (`moneda_id`) REFERENCES `core_monedas` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `finanzas_depreciaciones` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `asiento_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `monto` DECIMAL(14,2) NOT NULL DEFAULT 0,
  `fecha` DATE NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_finanzas_depreciaciones_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_finanzas_depreciaciones_asiento_id` FOREIGN KEY (`asiento_id`) REFERENCES `finanzas_asientos` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `finanzas_reportes` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `asiento_id` BIGINT UNSIGNED NULL,
  `usuario_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `monto` DECIMAL(14,2) NOT NULL DEFAULT 0,
  `fecha` DATE NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_finanzas_reportes_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_finanzas_reportes_asiento_id` FOREIGN KEY (`asiento_id`) REFERENCES `finanzas_asientos` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_finanzas_reportes_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `core_usuarios` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- ============================================================
-- Módulo: Logística
-- ============================================================

CREATE TABLE `logistica_envios` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `cantidad` INT NOT NULL DEFAULT 0,
  `fecha` DATE NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_logistica_envios_tenant` (`tenant_id`, `id`),
  CONSTRAINT `fk_logistica_envios_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `logistica_envio_lineas` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `envio_id` BIGINT UNSIGNED NOT NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `cantidad` INT NOT NULL DEFAULT 0,
  `fecha` DATE NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_logistica_envio_lineas_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_logistica_envio_lineas_tenant_envio` FOREIGN KEY (`tenant_id`, `envio_id`) REFERENCES `logistica_envios` (`tenant_id`, `id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `logistica_transportistas` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `envio_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `cantidad` INT NOT NULL DEFAULT 0,
  `fecha` DATE NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_logistica_transportistas_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_logistica_transportistas_envio_id` FOREIGN KEY (`envio_id`) REFERENCES `logistica_envios` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `logistica_rutas` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `envio_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `cantidad` INT NOT NULL DEFAULT 0,
  `fecha` DATE NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_logistica_rutas_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_logistica_rutas_envio_id` FOREIGN KEY (`envio_id`) REFERENCES `logistica_envios` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `logistica_paradas` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `envio_id` BIGINT UNSIGNED NULL,
  `usuario_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `cantidad` INT NOT NULL DEFAULT 0,
  `fecha` DATE NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_logistica_paradas_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_logistica_paradas_envio_id` FOREIGN KEY (`envio_id`) REFERENCES `logistica_envios` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_logistica_paradas_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `core_usuarios` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `logistica_guias` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `envio_id` BIGINT UNSIGNED NOT NULL UNIQUE,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `cantidad` INT NOT NULL DEFAULT 0,
  `fecha` DATE NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_logistica_guias_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_logistica_guias_envio_id` FOREIGN KEY (`envio_id`) REFERENCES `logistica_envios` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `logistica_incidencias` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `envio_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `cantidad` INT NOT NULL DEFAULT 0,
  `fecha` DATE NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_logistica_incidencias_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_logistica_incidencias_envio_id` FOREIGN KEY (`envio_id`) REFERENCES `logistica_envios` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `logistica_centros` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `envio_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `cantidad` INT NOT NULL DEFAULT 0,
  `fecha` DATE NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_logistica_centros_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_logistica_centros_envio_id` FOREIGN KEY (`envio_id`) REFERENCES `logistica_envios` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `logistica_vehiculos` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `envio_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `cantidad` INT NOT NULL DEFAULT 0,
  `fecha` DATE NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_logistica_vehiculos_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_logistica_vehiculos_envio_id` FOREIGN KEY (`envio_id`) REFERENCES `logistica_envios` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `logistica_conductores` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `envio_id` BIGINT UNSIGNED NULL,
  `usuario_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `cantidad` INT NOT NULL DEFAULT 0,
  `fecha` DATE NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_logistica_conductores_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_logistica_conductores_envio_id` FOREIGN KEY (`envio_id`) REFERENCES `logistica_envios` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_logistica_conductores_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `core_usuarios` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `logistica_tarifas` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `envio_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `cantidad` INT NOT NULL DEFAULT 0,
  `fecha` DATE NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_logistica_tarifas_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_logistica_tarifas_envio_id` FOREIGN KEY (`envio_id`) REFERENCES `logistica_envios` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `logistica_seguimientos` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `envio_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `cantidad` INT NOT NULL DEFAULT 0,
  `fecha` DATE NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_logistica_seguimientos_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_logistica_seguimientos_envio_id` FOREIGN KEY (`envio_id`) REFERENCES `logistica_envios` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `logistica_devoluciones` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `envio_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `cantidad` INT NOT NULL DEFAULT 0,
  `fecha` DATE NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_logistica_devoluciones_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_logistica_devoluciones_envio_id` FOREIGN KEY (`envio_id`) REFERENCES `logistica_envios` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `logistica_paquetes` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `envio_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `cantidad` INT NOT NULL DEFAULT 0,
  `fecha` DATE NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_logistica_paquetes_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_logistica_paquetes_envio_id` FOREIGN KEY (`envio_id`) REFERENCES `logistica_envios` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `logistica_zonas` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `envio_id` BIGINT UNSIGNED NULL,
  `usuario_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `cantidad` INT NOT NULL DEFAULT 0,
  `fecha` DATE NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_logistica_zonas_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_logistica_zonas_envio_id` FOREIGN KEY (`envio_id`) REFERENCES `logistica_envios` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_logistica_zonas_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `core_usuarios` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- ============================================================
-- Módulo: Proyectos
-- ============================================================

CREATE TABLE `proyectos_proyectos` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `fecha_inicio` DATE NULL,
  `fecha_fin` DATE NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_proyectos_proyectos_tenant` (`tenant_id`, `id`),
  CONSTRAINT `fk_proyectos_proyectos_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `proyectos_tareas` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `proyecto_id` BIGINT UNSIGNED NOT NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `fecha_inicio` DATE NULL,
  `fecha_fin` DATE NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_proyectos_tareas_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_proyectos_tareas_tenant_proyecto` FOREIGN KEY (`tenant_id`, `proyecto_id`) REFERENCES `proyectos_proyectos` (`tenant_id`, `id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `proyectos_fases` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `proyecto_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `fecha_inicio` DATE NULL,
  `fecha_fin` DATE NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_proyectos_fases_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_proyectos_fases_proyecto_id` FOREIGN KEY (`proyecto_id`) REFERENCES `proyectos_proyectos` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `proyectos_asignaciones` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `proyecto_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `fecha_inicio` DATE NULL,
  `fecha_fin` DATE NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_proyectos_asignaciones_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_proyectos_asignaciones_proyecto_id` FOREIGN KEY (`proyecto_id`) REFERENCES `proyectos_proyectos` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `proyectos_hitos` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `proyecto_id` BIGINT UNSIGNED NULL,
  `usuario_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `fecha_inicio` DATE NULL,
  `fecha_fin` DATE NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_proyectos_hitos_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_proyectos_hitos_proyecto_id` FOREIGN KEY (`proyecto_id`) REFERENCES `proyectos_proyectos` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_proyectos_hitos_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `core_usuarios` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `proyectos_riesgos` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `proyecto_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `fecha_inicio` DATE NULL,
  `fecha_fin` DATE NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_proyectos_riesgos_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_proyectos_riesgos_proyecto_id` FOREIGN KEY (`proyecto_id`) REFERENCES `proyectos_proyectos` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `proyectos_incidencias` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `proyecto_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `fecha_inicio` DATE NULL,
  `fecha_fin` DATE NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_proyectos_incidencias_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_proyectos_incidencias_proyecto_id` FOREIGN KEY (`proyecto_id`) REFERENCES `proyectos_proyectos` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `proyectos_documentos` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `proyecto_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `fecha_inicio` DATE NULL,
  `fecha_fin` DATE NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_proyectos_documentos_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_proyectos_documentos_proyecto_id` FOREIGN KEY (`proyecto_id`) REFERENCES `proyectos_proyectos` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `proyectos_tiempos` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `proyecto_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `fecha_inicio` DATE NULL,
  `fecha_fin` DATE NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_proyectos_tiempos_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_proyectos_tiempos_proyecto_id` FOREIGN KEY (`proyecto_id`) REFERENCES `proyectos_proyectos` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `proyectos_presupuestos` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `proyecto_id` BIGINT UNSIGNED NULL,
  `usuario_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `fecha_inicio` DATE NULL,
  `fecha_fin` DATE NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_proyectos_presupuestos_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_proyectos_presupuestos_proyecto_id` FOREIGN KEY (`proyecto_id`) REFERENCES `proyectos_proyectos` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_proyectos_presupuestos_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `core_usuarios` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `proyectos_gastos` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `proyecto_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `fecha_inicio` DATE NULL,
  `fecha_fin` DATE NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_proyectos_gastos_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_proyectos_gastos_proyecto_id` FOREIGN KEY (`proyecto_id`) REFERENCES `proyectos_proyectos` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `proyectos_equipos` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `proyecto_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `fecha_inicio` DATE NULL,
  `fecha_fin` DATE NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_proyectos_equipos_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_proyectos_equipos_proyecto_id` FOREIGN KEY (`proyecto_id`) REFERENCES `proyectos_proyectos` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `proyectos_entregables` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `proyecto_id` BIGINT UNSIGNED NULL,
  `tarea_id` BIGINT UNSIGNED NULL UNIQUE,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `fecha_inicio` DATE NULL,
  `fecha_fin` DATE NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_proyectos_entregables_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_proyectos_entregables_proyecto_id` FOREIGN KEY (`proyecto_id`) REFERENCES `proyectos_proyectos` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_proyectos_entregables_tarea_id` FOREIGN KEY (`tarea_id`) REFERENCES `proyectos_tareas` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `proyectos_revisiones` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `proyecto_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `fecha_inicio` DATE NULL,
  `fecha_fin` DATE NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_proyectos_revisiones_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_proyectos_revisiones_proyecto_id` FOREIGN KEY (`proyecto_id`) REFERENCES `proyectos_proyectos` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `proyectos_comentarios` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `proyecto_id` BIGINT UNSIGNED NULL,
  `usuario_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `fecha_inicio` DATE NULL,
  `fecha_fin` DATE NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_proyectos_comentarios_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_proyectos_comentarios_proyecto_id` FOREIGN KEY (`proyecto_id`) REFERENCES `proyectos_proyectos` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_proyectos_comentarios_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `core_usuarios` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- ============================================================
-- Módulo: Soporte
-- ============================================================

CREATE TABLE `soporte_tickets` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `fecha` DATE NULL,
  `detalle` TEXT NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_soporte_tickets_tenant` (`tenant_id`, `id`),
  CONSTRAINT `fk_soporte_tickets_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `soporte_mensajes` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `ticket_id` BIGINT UNSIGNED NOT NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `fecha` DATE NULL,
  `detalle` TEXT NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_soporte_mensajes_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_soporte_mensajes_tenant_ticket` FOREIGN KEY (`tenant_id`, `ticket_id`) REFERENCES `soporte_tickets` (`tenant_id`, `id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `soporte_categorias` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `ticket_id` BIGINT UNSIGNED NULL,
  `parent_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `fecha` DATE NULL,
  `detalle` TEXT NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_soporte_categorias_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_soporte_categorias_ticket_id` FOREIGN KEY (`ticket_id`) REFERENCES `soporte_tickets` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_soporte_categorias_parent` FOREIGN KEY (`parent_id`) REFERENCES `soporte_categorias` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `soporte_prioridades` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `ticket_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `fecha` DATE NULL,
  `detalle` TEXT NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_soporte_prioridades_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_soporte_prioridades_ticket_id` FOREIGN KEY (`ticket_id`) REFERENCES `soporte_tickets` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `soporte_estados` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `ticket_id` BIGINT UNSIGNED NULL,
  `usuario_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `fecha` DATE NULL,
  `detalle` TEXT NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_soporte_estados_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_soporte_estados_ticket_id` FOREIGN KEY (`ticket_id`) REFERENCES `soporte_tickets` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_soporte_estados_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `core_usuarios` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `soporte_agentes` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `ticket_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `fecha` DATE NULL,
  `detalle` TEXT NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_soporte_agentes_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_soporte_agentes_ticket_id` FOREIGN KEY (`ticket_id`) REFERENCES `soporte_tickets` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `soporte_sla` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `ticket_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `fecha` DATE NULL,
  `detalle` TEXT NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_soporte_sla_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_soporte_sla_ticket_id` FOREIGN KEY (`ticket_id`) REFERENCES `soporte_tickets` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `soporte_escalamientos` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `ticket_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `fecha` DATE NULL,
  `detalle` TEXT NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_soporte_escalamientos_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_soporte_escalamientos_ticket_id` FOREIGN KEY (`ticket_id`) REFERENCES `soporte_tickets` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `soporte_soluciones` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `ticket_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `fecha` DATE NULL,
  `detalle` TEXT NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_soporte_soluciones_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_soporte_soluciones_ticket_id` FOREIGN KEY (`ticket_id`) REFERENCES `soporte_tickets` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `soporte_articulos` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `ticket_id` BIGINT UNSIGNED NULL,
  `usuario_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `fecha` DATE NULL,
  `detalle` TEXT NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_soporte_articulos_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_soporte_articulos_ticket_id` FOREIGN KEY (`ticket_id`) REFERENCES `soporte_tickets` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_soporte_articulos_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `core_usuarios` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `soporte_encuestas` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `ticket_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `fecha` DATE NULL,
  `detalle` TEXT NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_soporte_encuestas_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_soporte_encuestas_ticket_id` FOREIGN KEY (`ticket_id`) REFERENCES `soporte_tickets` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `soporte_satisfaccion` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `ticket_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `fecha` DATE NULL,
  `detalle` TEXT NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_soporte_satisfaccion_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_soporte_satisfaccion_ticket_id` FOREIGN KEY (`ticket_id`) REFERENCES `soporte_tickets` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `soporte_incidentes` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `ticket_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `fecha` DATE NULL,
  `detalle` TEXT NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_soporte_incidentes_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_soporte_incidentes_ticket_id` FOREIGN KEY (`ticket_id`) REFERENCES `soporte_tickets` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `soporte_cambios` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `ticket_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `fecha` DATE NULL,
  `detalle` TEXT NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_soporte_cambios_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_soporte_cambios_ticket_id` FOREIGN KEY (`ticket_id`) REFERENCES `soporte_tickets` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `soporte_problemas` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `ticket_id` BIGINT UNSIGNED NULL,
  `usuario_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `fecha` DATE NULL,
  `detalle` TEXT NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_soporte_problemas_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_soporte_problemas_ticket_id` FOREIGN KEY (`ticket_id`) REFERENCES `soporte_tickets` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_soporte_problemas_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `core_usuarios` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- ============================================================
-- Módulo: RR. HH.
-- ============================================================

CREATE TABLE `rrhh_nominas` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `fecha` DATE NULL,
  `monto` DECIMAL(14,2) NOT NULL DEFAULT 0,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_rrhh_nominas_tenant` (`tenant_id`, `id`),
  CONSTRAINT `fk_rrhh_nominas_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `rrhh_nomina_lineas` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `nomina_id` BIGINT UNSIGNED NOT NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `fecha` DATE NULL,
  `monto` DECIMAL(14,2) NOT NULL DEFAULT 0,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_rrhh_nomina_lineas_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_rrhh_nomina_lineas_tenant_nomina` FOREIGN KEY (`tenant_id`, `nomina_id`) REFERENCES `rrhh_nominas` (`tenant_id`, `id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `rrhh_empleados` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `nomina_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `fecha` DATE NULL,
  `monto` DECIMAL(14,2) NOT NULL DEFAULT 0,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_rrhh_empleados_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_rrhh_empleados_nomina_id` FOREIGN KEY (`nomina_id`) REFERENCES `rrhh_nominas` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `rrhh_departamentos` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `nomina_id` BIGINT UNSIGNED NULL,
  `parent_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `fecha` DATE NULL,
  `monto` DECIMAL(14,2) NOT NULL DEFAULT 0,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_rrhh_departamentos_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_rrhh_departamentos_nomina_id` FOREIGN KEY (`nomina_id`) REFERENCES `rrhh_nominas` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_rrhh_departamentos_parent` FOREIGN KEY (`parent_id`) REFERENCES `rrhh_departamentos` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `rrhh_puestos` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `nomina_id` BIGINT UNSIGNED NULL,
  `usuario_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `fecha` DATE NULL,
  `monto` DECIMAL(14,2) NOT NULL DEFAULT 0,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_rrhh_puestos_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_rrhh_puestos_nomina_id` FOREIGN KEY (`nomina_id`) REFERENCES `rrhh_nominas` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_rrhh_puestos_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `core_usuarios` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `rrhh_contratos` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `nomina_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `fecha` DATE NULL,
  `monto` DECIMAL(14,2) NOT NULL DEFAULT 0,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_rrhh_contratos_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_rrhh_contratos_nomina_id` FOREIGN KEY (`nomina_id`) REFERENCES `rrhh_nominas` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `rrhh_asistencias` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `nomina_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `fecha` DATE NULL,
  `monto` DECIMAL(14,2) NOT NULL DEFAULT 0,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_rrhh_asistencias_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_rrhh_asistencias_nomina_id` FOREIGN KEY (`nomina_id`) REFERENCES `rrhh_nominas` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `rrhh_vacaciones` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `nomina_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `fecha` DATE NULL,
  `monto` DECIMAL(14,2) NOT NULL DEFAULT 0,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_rrhh_vacaciones_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_rrhh_vacaciones_nomina_id` FOREIGN KEY (`nomina_id`) REFERENCES `rrhh_nominas` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `rrhh_licencias` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `nomina_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `fecha` DATE NULL,
  `monto` DECIMAL(14,2) NOT NULL DEFAULT 0,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_rrhh_licencias_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_rrhh_licencias_nomina_id` FOREIGN KEY (`nomina_id`) REFERENCES `rrhh_nominas` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `rrhh_evaluaciones` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `nomina_id` BIGINT UNSIGNED NULL,
  `usuario_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `fecha` DATE NULL,
  `monto` DECIMAL(14,2) NOT NULL DEFAULT 0,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_rrhh_evaluaciones_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_rrhh_evaluaciones_nomina_id` FOREIGN KEY (`nomina_id`) REFERENCES `rrhh_nominas` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_rrhh_evaluaciones_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `core_usuarios` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `rrhh_capacitaciones` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `nomina_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `fecha` DATE NULL,
  `monto` DECIMAL(14,2) NOT NULL DEFAULT 0,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_rrhh_capacitaciones_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_rrhh_capacitaciones_nomina_id` FOREIGN KEY (`nomina_id`) REFERENCES `rrhh_nominas` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `rrhh_beneficios` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `nomina_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `fecha` DATE NULL,
  `monto` DECIMAL(14,2) NOT NULL DEFAULT 0,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_rrhh_beneficios_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_rrhh_beneficios_nomina_id` FOREIGN KEY (`nomina_id`) REFERENCES `rrhh_nominas` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `rrhh_reclutamiento` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `nomina_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `fecha` DATE NULL,
  `monto` DECIMAL(14,2) NOT NULL DEFAULT 0,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_rrhh_reclutamiento_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_rrhh_reclutamiento_nomina_id` FOREIGN KEY (`nomina_id`) REFERENCES `rrhh_nominas` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `rrhh_candidatos` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `nomina_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `fecha` DATE NULL,
  `monto` DECIMAL(14,2) NOT NULL DEFAULT 0,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_rrhh_candidatos_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_rrhh_candidatos_nomina_id` FOREIGN KEY (`nomina_id`) REFERENCES `rrhh_nominas` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `rrhh_historial` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` BIGINT UNSIGNED NOT NULL,
  `nomina_id` BIGINT UNSIGNED NULL,
  `usuario_id` BIGINT UNSIGNED NULL,
  `codigo` VARCHAR(40) NOT NULL UNIQUE,
  `nombre` VARCHAR(120) NOT NULL,
  `fecha` DATE NULL,
  `monto` DECIMAL(14,2) NOT NULL DEFAULT 0,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'activo',
  `creado_en` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `actualizado_en` DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_rrhh_historial_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `core_empresas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_rrhh_historial_nomina_id` FOREIGN KEY (`nomina_id`) REFERENCES `rrhh_nominas` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_rrhh_historial_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `core_usuarios` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

SET FOREIGN_KEY_CHECKS = 1;
