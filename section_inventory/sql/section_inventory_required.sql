-- section_inventory only
-- ไฟล์นี้สร้างเฉพาะตารางของ resource section_inventory
-- (ไม่แก้ไขตาราง users/items ของ ESX)

USE `es_extended`;

CREATE TABLE IF NOT EXISTS `section_inventory` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `identifier` VARCHAR(64) NOT NULL,
    `data` LONGTEXT NULL,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uniq_section_inventory_identifier` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
