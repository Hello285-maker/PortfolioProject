
-- Checking for all the Data Present in the Table

SELECT *
FROM Data_Cleaning.dbo.NashvilleHousing


--Creating a Column named SaleDateConverted to store the Date, without the time. 
ALTER TABLE NashvilleHousing
ADD SaleDateConverted Date;


--Updating the Entries to the new column by using the Update Function and then setting the entries for the column to the date alone by using the function CONVERT
UPDATE Data_Cleaning.dbo.NashvilleHousing
SET SaleDateConverted=Convert(Date,SaleDate)


--Checking whether the changes to the column were implemented
SELECT SaleDate, SaleDateConverted
FROM Data_Cleaning.dbo.NashvilleHousing



-----------------------------------------------Populating Property Address---------------------------------------------------------------------------


--Checking for the presence of Null Property Address Cells
SELECT PropertyAddress
FROM Data_Cleaning.dbo.NashvilleHousing
WHERE PropertyAddress IS NULL


--Checking for common features from different OrderIDs. It was found that there was a unique and unchanged ParcelID for each address.
SELECT ParcelID, LandUse, PropertyAddress
FROM Data_Cleaning.dbo.NashvilleHousing
ORDER BY ParcelID


--Checking for all of the Property Address with NULL value which has a repeating ParcelID
SELECT NULLPropertyAddress.ParcelID, NULLPropertyAddress.PropertyAddress , FillingPropertyAddress.ParcelID, FillingPropertyAddress.PropertyAddress, ISNULL(NULLPropertyAddress.PropertyAddress,FillingPropertyAddress.PropertyAddress) 
FROM Data_Cleaning.dbo.NashvilleHousing NULLPropertyAddress
JOIN Data_Cleaning.dbo.NashvilleHousing FillingPropertyAddress
	ON NULLPropertyAddress.ParcelID=FillingPropertyAddress.ParcelID
	AND NULLPropertyAddress.[UniqueID ] <> FillingPropertyAddress.[UniqueID ]
WHERE NULLPropertyAddress.PropertyAddress is NULL


--Updating the Property Address Value where its value is NULL
UPDATE NULLPropertyAddress
SET PropertyAddress= ISNULL(NULLPropertyAddress.PropertyAddress,FillingPropertyAddress.PropertyAddress) 
FROM Data_Cleaning.dbo.NashvilleHousing NULLPropertyAddress
JOIN Data_Cleaning.dbo.NashvilleHousing FillingPropertyAddress
	ON NULLPropertyAddress.ParcelID=FillingPropertyAddress.ParcelID
	AND NULLPropertyAddress.[UniqueID ] <> FillingPropertyAddress.[UniqueID ]
WHERE NULLPropertyAddress.PropertyAddress is NULL


--Checking again to see if there are any NULL values present for Property Address 
SELECT ParcelID,PropertyAddress 
FROM Data_Cleaning.dbo.NashvilleHousing 
WHERE PropertyAddress is NULL


-----------------------------------------------Breaking the Address into (Address, City, State)---------------------------------------------------------------------

--Checking the Property Address to see if certain cell has more than 1 Delimiter (,)
SELECT PropertyAddress
FROM Data_Cleaning.dbo.NashvilleHousing 
--WHERE PropertyAddress LIKE '%,%,%'
WHERE PropertyAddress LIKE '%,%'


--Using SUBSTRING function to go through the PropertyAddress String and using CHARINDEX to find the index of the delimiter 
SELECT SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress)-1) AS Address, SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress)+1, LEN(PropertyAddress)) AS State
FROM Data_Cleaning.dbo.NashvilleHousing


--Creating New Columns to seperate Address and State into different columns
ALTER TABLE Data_Cleaning.dbo.NashvilleHousing
ADD Property_Address nvarchar(255)

UPDATE Data_Cleaning.dbo.NashvilleHousing
SET Property_Address= SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress)-1)



ALTER TABLE Data_Cleaning.dbo.NashvilleHousing
ADD Property_State nvarchar(255)

UPDATE Data_Cleaning.dbo.NashvilleHousing
SET Property_State= SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress)+1, LEN(PropertyAddress))


SELECT PropertyAddress, Property_State, Property_Address 
FROM Data_Cleaning.dbo.NashvilleHousing


--Breaking the Owner Address into (Address, City, State) using PARSENAME to seperate the texts and REPLACE to replace the delimiters to '.'

SELECT PARSENAME(Replace(OwnerAddress,',','.'),3), PARSENAME(Replace(OwnerAddress,',','.'),2), PARSENAME(Replace(OwnerAddress,',','.'),1) 
FROM Data_Cleaning.dbo.NashvilleHousing


ALTER TABLE Data_Cleaning.dbo.NashvilleHousing
ADD OwnerSplitAddress nvarchar(255)

UPDATE Data_Cleaning.dbo.NashvilleHousing
SET OwnerSplitAddress= PARSENAME(Replace(OwnerAddress,',','.'),3)

ALTER TABLE Data_Cleaning.dbo.NashvilleHousing
ADD OwnerSplitCity nvarchar(255)

UPDATE Data_Cleaning.dbo.NashvilleHousing
SET OwnerSplitCity= PARSENAME(Replace(OwnerAddress,',','.'),2)

ALTER TABLE Data_Cleaning.dbo.NashvilleHousing
ADD OwnerSplitState nvarchar(255)

UPDATE Data_Cleaning.dbo.NashvilleHousing
SET OwnerSplitState= PARSENAME(Replace(OwnerAddress,',','.'),1)


SELECT OwnerAddress, OwnerSplitAddress, OwnerSplitCity, OwnerSplitState
FROM Data_Cleaning.dbo.NashvilleHousing



-----------------------------------------------Making the Data Consistent-------------------------------------------------------------------

SELECT Distinct(SoldAsVacant), Count(SoldAsVacant)
FROM Data_Cleaning.dbo.NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2

--Matching the Data with the response format which has higher count, in this case that is Yes/No

SELECT SoldAsVacant,
CASE WHEN SoldAsVacant= 'N' THEN 'No'
			WHEN SoldAsVacant= 'Y' THEN 'Yes'
			ELSE SoldAsVacant
			END
FROM Data_Cleaning.dbo.NashvilleHousing


UPDATE Data_Cleaning.dbo.NashvilleHousing
SET SoldAsVacant=CASE WHEN SoldAsVacant= 'N' THEN 'No'
				 WHEN SoldAsVacant= 'Y' THEN 'Yes'
				 ELSE SoldAsVacant
				 END

SELECT DISTINCT(SoldAsVacant)
FROM Data_Cleaning.dbo.NashvilleHousing


-------------------------------------------------------Removing Duplicate Data-----------------------------------------------------------------
--Creating a CTE to not delete from the raw dataset.
--Using Row_Number to determine the rows where the ParcelID, PropertyAddress, SalePrice, SaleDate and LegalReferences are repeated for 1 item.
WITH RowNumCTE AS(
SELECT *, ROW_NUMBER() OVER (PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference ORDER BY UniqueID) AS row_num
FROM Data_Cleaning.dbo.NashvilleHousing
)
DELETE
FROM RowNumCTE
WHERE row_num>1





---------------------------------------------------Removing Unused Cells---------------------------------------------------------------------
SELECT*
FROM Data_Cleaning.dbo.NashvilleHousing

ALTER TABLE Data_Cleaning.dbo.NashvilleHousing
DROP COLUMN PropertyAddress, OwnerAddress, TaxDistrict
