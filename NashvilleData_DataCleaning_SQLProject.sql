/*
Cleaning data in SQL queries
*/

-- 1. View data to make sure everything is loaded

SELECT *
FROM `Cleaning.nashville_housing_data`;
-----------------------------------------------------------------

-- Standardize date format

SELECT
  SaleDate,
  CAST(SaleDate AS date) AS SaleDateCleaned
FROM `Cleaning.nashville_housing_data` AS nash;


ALTER TABLE `Cleaning.nashville_housing_data`
ADD SaleDateConverted Date;


UPDATE `Cleaning.nashville_housing_data`
SET SaleDate = CAST(SaleDate AS date);


SELECT
  SaleDate,
  SaleDateConverted
FROM `Cleaning.nashville_housing_data` AS nash;

-----------------------------------------------------------------

-- Populate missing/null property address data

SELECT PropertyAddress
FROM `Cleaning.nashville_housing_data`;


SELECT PropertyAddress
FROM `Cleaning.nashville_housing_data`
WHERE PropertyAddress IS NULL;


SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, IFNULL(b.PropertyAddress, a.PropertyAddress) AS denullified
FROM `Cleaning.nashville_housing_data` AS a
INNER JOIN `Cleaning.nashville_housing_data` AS b
  ON a.ParcelID = b.ParcelID
    AND a.UniqueID_ <> b.UniqueID_
WHERE a.PropertyAddress IS NULL;


UPDATE a
SET PropertyAddress = IFNULL(b.PropertyAddress, a.PropertyAddress)
FROM `Cleaning.nashville_housing_data` AS a
INNER JOIN `Cleaning.nashville_housing_data` AS b
  ON a.ParcelID = b.ParcelID
    AND a.UniqueID_ <> b.UniqueID_

-----------------------------------------------------------------

-- Break-out address into individual columns (address, city, state)

SELECT PropertyAddress
FROM `Cleaning.nashville_housing_data`;


SELECT SUBSTR(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) AS Address
FROM `Cleaning.nashville_housing_data`;


SELECT 
  SUBSTR(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) AS Address,
  SUBSTR(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LENGTH(PropertyAddress)) AS City
FROM `Cleaning.nashville_housing_data`;


ALTER TABLE `Cleaning.nashville_housing_data`
ADD CleanedAddress NVARCHAR(255);


UPDATE `Cleaning.nashville_housing_data`
SET CleanedAddress = SUBSTR(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1);


ALTER TABLE `Cleaning.nashville_housing_data`
ADD CleanedCity NVARCHAR(255);


UPDATE `Cleaning.nashville_housing_data`
SET CleanedCity = SUBSTR(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1);


SELECT *
FROM `Cleaning.nashville_housing_data`;

--- Different Method ---

SELECT PropertyAddress
FROM `Cleaning.nashville_housing_data`;


SELECT 
  REGEXP_EXTRACT(PropertyAddress, r'(.*?),') AS PropertyAddress,
  REGEXP_EXTRACT(PropertyAddress, r',(.*)') AS PropertyCity
FROM `Cleaning.nashville_housing_data`;


ALTER TABLE `Cleaning.nashville_housing_data`
ADD NewPropertyAddress NVARCHAR(255);


UPDATE `Cleaning.nashville_housing_data`
SET NewPropertyAddress = REGEXP_EXTRACT(PropertyAddress, r'(.*?),');


ALTER TABLE `Cleaning.nashville_housing_data`
ADD NewPropertyCity NVARCHAR(255);


UPDATE `Cleaning.nashville_housing_data`
SET NewPropertyCity = REGEXP_EXTRACT(PropertyAddress, r',(.*)');

---- Different field ----

SELECT PropertyAddress
FROM `Cleaning.nashville_housing_data`;


SELECT 
  PARSENAME(REPLACE(OwnerAddress, ',','.'), 3),
  PARSENAME(REPLACE(OwnerAddress, ',','.'), 2),
  PARSENAME(REPLACE(OwnerAddress, ',','.'), 1)
FROM `Cleaning.nashville_housing_data`;


ALTER TABLE `Cleaning.nashville_housing_data`
ADD NewOwnerAddress NVARCHAR(255);


UPDATE `Cleaning.nashville_housing_data`
SET NewOwnerAddress = PARSENAME(REPLACE(OwnerAddress, ',','.'), 3);


ALTER TABLE `Cleaning.nashville_housing_data`
ADD NewOwnerCity NVARCHAR(255);


UPDATE `Cleaning.nashville_housing_data`
SET NewOwnerCity = PARSENAME(REPLACE(OwnerAddress, ',','.'), 2);


ALTER TABLE `Cleaning.nashville_housing_data`
ADD NewOwnerState NVARCHAR(255);


UPDATE `Cleaning.nashville_housing_data`
SET NewOwnerState = PARSENAME(REPLACE(OwnerAddress, ',','.'), 1);


-----------------------------------------------------------------

-- Change Y and N to Yes and No in the "Sold as Vacant" field

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM `Cleaning.nashville_housing_data`
GROUP BY SoldAsVacant
ORDER BY 2;


SELECT
  CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
    WHEN SoldAsVacant = 'N' THEN 'No'
    ELSE SoldAsVacant 
    END
FROM `Cleaning.nashville_housing_data`;


UPDATE `Cleaning.nashville_housing_data`
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
                    WHEN SoldAsVacant = 'N' THEN 'No'
                    ELSE SoldAsVacant 
                    END;


-----------------------------------------------------------------

-- Remove duplicates

WITH row_numCTE AS (
SELECT *,
  ROW_NUMBER() OVER (PARTITION BY  ParcelID,
                  PropertyAddress,
                  SalePrice,
                  SaleDate,
                  LegalReference
                  ORDER BY UniqueID_
                  ) row_num

FROM `Cleaning.nashville_housing_data`
)
SELECT *
FROM row_numCTE
WHERE row_num > 1
ORDER BY PropertyAddress;


WITH row_numCTE AS (
SELECT *,
  ROW_NUMBER() OVER (PARTITION BY  ParcelID,
                  PropertyAddress,
                  SalePrice,
                  SaleDate,
                  LegalReference
                  ORDER BY UniqueID_
                  ) row_num

FROM `Cleaning.nashville_housing_data`
)
DELETE
FROM row_numCTE
WHERE row_num > 1;

-----------------------------------------------------------------

-- Delete unused columns

ALTER TABLE `Cleaning.nashville_housing_data`
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate

