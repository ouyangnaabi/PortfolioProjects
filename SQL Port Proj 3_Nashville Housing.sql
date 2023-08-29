--Portfolio Project Part3 : Cleaning Data In SQL Queries--



--(A)Standardlise date format--------------------------------------------------------------

--Change the date format to just YY-MM-DD
select SaleDate2
from PortfolioProject..NashvilleHousing

Alter table PortfolioProject..NashvilleHousing
Add SaleDate2 Date;

Update PortfolioProject..NashvilleHousing
Set SaleDate2 = convert(Date, SaleDate)




--(B)Populate Property Address Data-----------------------------------------------------------

--After the final step, run this again then you will find no more NULL on PropertyAddress column !
select *
from PortfolioProject..NashvilleHousing
order by ParcelID 


--When there are properties that has different parcel ID but share the same address, we populate(fill up) them,
--fill them up w/ their corresponding addresses

select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, 
ISNULL(a.PropertyAddress,b.PropertyAddress)-- fills all null values in A with values in B(in this case, the addresses)
from PortfolioProject..NashvilleHousing a
join PortfolioProject..NashvilleHousing b
	on a.ParcelID = b.ParcelID
	and a.UniqueID <> b.UniqueID
where a.PropertyAddress is null


--Use an Update statement to fill up the addresses in A
Update a
set PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
from PortfolioProject..NashvilleHousing a
join PortfolioProject..NashvilleHousing b
	on a.ParcelID = b.ParcelID
	and a.UniqueID <> b.UniqueID
where a.PropertyAddress is null 
--Then run the select Join query again, if no output are returned, then the ISNULL() works!







-- (C)Breaking out Address into Individual Columns (Address/ City/ State)--------------------------
 
-- PART 1: Split the property address into Address/City
select PropertyAddress
from PortfolioProject..NashvilleHousing

--1)we want to take away the city name and the ',':
select substring(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) as Address, -- starting at first value and go until the char before ',' (-1)
--charindex(',', PropertyAddress) -- this tells the position of the ','

--2)to get just the city name by itself:
substring(PropertyAddress, CHARINDEX(',', PropertyAddress) +1 , len(PropertyAddress))
-- start at the char after ","(+1), then end at the length() of each string value^

from PortfolioProject..NashvilleHousing

--3) Create 2 new columns and add the values(single address & city name) above into them:

Alter table PortfolioProject..NashvilleHousing
Add PropertySplitAddress Nvarchar(255);

Update PortfolioProject..NashvilleHousing
Set PropertySplitAddress = substring(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1)

Alter table PortfolioProject..NashvilleHousing
Add PropertyCity Nvarchar(255);

Update PortfolioProject..NashvilleHousing
Set PropertyCity = substring(PropertyAddress, CHARINDEX(',', PropertyAddress) +1 , len(PropertyAddress))




--PART 2: Split the owners' addresses into address/city/state without using SUBSTRING

select OwnerAddress
from PortfolioProject..NashvilleHousing

--1)Use PARSENAME() to split, first change ',' to '.' then set up range(1,2,3) 
select 
PARSENAME(replace(OwnerAddress , ',', '.') ,3), -- parsename always cuts from the end, so do it from 3 to 1
PARSENAME(replace(OwnerAddress , ',', '.') ,2),
PARSENAME(replace(OwnerAddress , ',', '.') ,1)
from PortfolioProject..NashvilleHousing




--2) Create 3 new columns and add the values from above:
Alter table PortfolioProject..NashvilleHousing
Add OwnerSplitAddress Nvarchar(255);

Update PortfolioProject..NashvilleHousing
Set OwnerSplitAddress = PARSENAME(replace(OwnerAddress , ',', '.') ,3)

Alter table PortfolioProject..NashvilleHousing
Add OwnerSplitCity Nvarchar(255);

Update PortfolioProject..NashvilleHousing
Set OwnerSplitCity = PARSENAME(replace(OwnerAddress , ',', '.') ,2)

Alter table PortfolioProject..NashvilleHousing
Add OwnerSplitState Nvarchar(255);

Update PortfolioProject..NashvilleHousing
Set OwnerSplitState = PARSENAME(replace(OwnerAddress , ',', '.') ,1)








-- (D)Change 1 and 0 to Yes and No in 'Sold as Vacant' field-------------------------------------

--1)Find out all counts for the yes' and no's (in this case, 1's and 0's)
Select distinct (SoldAsVacant), count(SoldAsVacant)
from PortfolioProject..NashvilleHousing
Group by SoldAsVacant
order by 2

--2)Use a case to change the 1&0 to Yes&No
Select SoldAsVacant,
case when cast(SoldAsVacant as nvarchar(50))= '1' then 'Yes'
	 when cast(SoldAsVacant as nvarchar(50)) = '0' then 'No'
	 else cast(SoldAsVacant as nvarchar(50))
	 end as SoldAsVacantVar
from PortfolioProject..NashvilleHousing





--(E) Removing duplicates--------------------------------------------------------------------------

--Use CTE and window functions, partition on things that are unique, if '2' shows up under 'row_num', that means it's a duplicate

WITH RowNumCTE as(
select *, 
	ROW_NUMBER()over(
	partition by ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 order by 
					UniqueID
					) row_num

from PortfolioProject..NashvilleHousing
--order by ParcelID
)



--DELETE (the duplicates)
select *
from RowNumCTE
where row_num > 1
order by PropertyAddress








--(F) Delete Unused Columns-------------------------------------------------------------------------

--Take out the ones that are not useful, keep the ones that are more user-friendly
select *
from PortfolioProject..NashvilleHousing

ALTER TABLE PortfolioProject..NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress

ALTER TABLE PortfolioProject..NashvilleHousing
DROP COLUMN SaleDate











--- Importing Data using OPENROWSET and BULK INSERT	----------------------------------------------------------

--  More advanced and looks cooler, but have to configure server appropriately to do correctly
--  Wanted to provide this in case you wanted to try it


--sp_configure 'show advanced options', 1;
--RECONFIGURE;
--GO
--sp_configure 'Ad Hoc Distributed Queries', 1;
--RECONFIGURE;
--GO


--USE PortfolioProject 

--GO 

--EXEC master.dbo.sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'AllowInProcess', 1 

--GO 

--EXEC master.dbo.sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'DynamicParameters', 1 

--GO 


---- Using BULK INSERT

--USE PortfolioProject;
--GO
--BULK INSERT nashvilleHousing FROM 'C:\Temp\SQL Server Management Studio\Nashville Housing Data for Data Cleaning Project.csv'
--   WITH (
--      FIELDTERMINATOR = ',',
--      ROWTERMINATOR = '\n'
--);
--GO


---- Using OPENROWSET
--USE PortfolioProject;
--GO
--SELECT * INTO nashvilleHousing
--FROM OPENROWSET('Microsoft.ACE.OLEDB.12.0',
--    'Excel 12.0; Database=C:\Users\alexf\OneDrive\Documents\SQL Server Management Studio\Nashville Housing Data for Data Cleaning Project.csv', [Sheet1$]);
--GO



