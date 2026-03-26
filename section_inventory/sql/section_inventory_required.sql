-- section_inventory required database migration
-- Import this file into your ESX database (usually `es_extended`).

USE `es_extended`;

-- Required user fields used by ESX + section_inventory flow
ALTER TABLE `users`
    ADD COLUMN IF NOT EXISTS `accounts` LONGTEXT NULL DEFAULT NULL AFTER `identifier`,
    ADD COLUMN IF NOT EXISTS `group` VARCHAR(50) NULL DEFAULT 'user' AFTER `accounts`,
    ADD COLUMN IF NOT EXISTS `inventory` LONGTEXT NULL DEFAULT NULL AFTER `group`,
    ADD COLUMN IF NOT EXISTS `job` VARCHAR(20) NULL DEFAULT 'unemployed' AFTER `inventory`,
    ADD COLUMN IF NOT EXISTS `job_grade` INT NULL DEFAULT 0 AFTER `job`,
    ADD COLUMN IF NOT EXISTS `loadout` LONGTEXT NULL DEFAULT NULL AFTER `job_grade`,
    ADD COLUMN IF NOT EXISTS `metadata` LONGTEXT NULL DEFAULT NULL AFTER `loadout`,
    ADD COLUMN IF NOT EXISTS `position` LONGTEXT NULL DEFAULT NULL AFTER `metadata`,
    ADD COLUMN IF NOT EXISTS `version` INT NOT NULL DEFAULT 0 AFTER `position`;

-- Required item fields
ALTER TABLE `items`
    ADD COLUMN IF NOT EXISTS `weight` INT NOT NULL DEFAULT 1 AFTER `label`,
    ADD COLUMN IF NOT EXISTS `limit` INT NOT NULL DEFAULT -1 AFTER `weight`,
    ADD COLUMN IF NOT EXISTS `rare` TINYINT NOT NULL DEFAULT 0 AFTER `limit`,
    ADD COLUMN IF NOT EXISTS `can_remove` TINYINT NOT NULL DEFAULT 1 AFTER `rare`;
