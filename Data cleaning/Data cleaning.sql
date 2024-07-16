/*

Cleaning Data in SQL Queries

*/

select * 
from PortfolioProject.dbo.Data_for_Data_Cleaning



---------------------------------------------------------------------------------------------------------
-- Standartize Date Format

select SaleDate, convert(Date,SaleDate)
from PortfolioProject.dbo.Data_for_Data_Cleaning
GO
update PortfolioProject.dbo.Data_for_Data_Cleaning
set SaleDate = convert(Date, SaleDate)


--create a new column SaleDateConverted with a standardized data format

alter table Data_for_Data_Cleaning
Add SaleDateConverted Date
GO
update PortfolioProject.dbo.Data_for_Data_Cleaning
set SaleDateConverted = convert(Date, SaleDate)



---------------------------------------------------------------------------------------------------------
-- Populate Property Address data
-- the idea is to join the table to itself to look at if ParcelID corresponds to definite to PropertyAddress(considering the UniqueID), 
-- If the PropertyAddress is empty, then find the same ParcelID with the existing PropertyAddress and insert it into the empty space.

select PropertyAddress
from PortfolioProject.dbo.Data_for_Data_Cleaning
where PropertyAddress is NULL
order by ParcelID

select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress,b.PropertyAddress)
from PortfolioProject.dbo.Data_for_Data_Cleaning a
join PortfolioProject.dbo.Data_for_Data_Cleaning b
	on a.ParcelID = b.ParcelID
	and a.[UniqueID ] <> b.[UniqueID ]
where a.PropertyAddress is NULL

update a
set PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)                             -- also instead of b.PropertyAddress we can put "No Address" note here
from PortfolioProject.dbo.Data_for_Data_Cleaning a
join PortfolioProject.dbo.Data_for_Data_Cleaning b
	on a.ParcelID = b.ParcelID
	and a.[UniqueID ] <> b.[UniqueID ]
where a.PropertyAddress is NULL



---------------------------------------------------------------------------------------------------------
-- Breaking out Address into Individual Columns (Adrress, City, State)

select PropertyAddress
from PortfolioProject.dbo.Data_for_Data_Cleaning
where PropertyAddress is NULL
order by ParcelID

select 
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) as Address,                  -- take the first part of string before ',' where -1 exclude this ','
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +2, LEN(PropertyAddress)) as City   -- take the second part after the ',' and put it separately where +2 give us to start after two symbols after the ',' 

from PortfolioProject.dbo.Data_for_Data_Cleaning


-- PropertySplitAddress

alter table Data_for_Data_Cleaning                                                             -- add one column in the end of the table with a name PropertySplitAddress
Add PropertySplitAddress nvarchar(255)

update Data_for_Data_Cleaning                                                                  -- insert data into a column PropertySplitAddress
set PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1)


-- PropertySplitCity

alter table Data_for_Data_Cleaning                                                             
Add PropertySplitCity nvarchar(255)

update Data_for_Data_Cleaning                                                                 
set PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +2, LEN(PropertyAddress))


select OwnerAddress
from PortfolioProject.dbo.Data_for_Data_Cleaning

select
PARSENAME(replace(OwnerAddress, ',', '.') ,3),                                                 -- extract the third ("database") part of OwnerAddress
PARSENAME(replace(OwnerAddress, ',', '.') ,2),                                                 -- extract the second ("schema") part of OwnerAddress
PARSENAME(replace(OwnerAddress, ',', '.') ,1)                                                  -- extract the first ("object") part of OwnerAddress
from PortfolioProject.dbo.Data_for_Data_Cleaning


-- OwnerSplitAddress

alter table Data_for_Data_Cleaning                                                             -- add one column in the end of the table with a name PropertySplitAddress
Add OwnerSplitAddress nvarchar(255)

update Data_for_Data_Cleaning                                                                  -- insert data into a column PropertySplitAddress
set OwnerSplitAddress = PARSENAME(replace(OwnerAddress, ',', '.') ,3)


-- OwnerSplitCity

alter table Data_for_Data_Cleaning                                                             
Add OwnerSplitCity nvarchar(255)

update Data_for_Data_Cleaning                                                                 
set OwnerSplitCity = PARSENAME(replace(OwnerAddress, ',', '.') ,2)


-- OwnerSplitState

alter table Data_for_Data_Cleaning                                                             
Add OwnerSplitState nvarchar(255)

update Data_for_Data_Cleaning                                                                 
set OwnerSplitState = PARSENAME(replace(OwnerAddress, ',', '.') ,1)



---------------------------------------------------------------------------------------------------------
-- Change Y and N to Yes and No in "Sold as Vacant" field

select distinct(SoldAsVacant), count(SoldAsVacant)                                              -- to see only distinct (unique) values from a specified column + count it 
from PortfolioProject.dbo.Data_for_Data_Cleaning
group by SoldAsVacant
order by 2


select SoldAsVacant
, case when SoldAsVacant = 'Y' then 'Yes'                                                       -- to change values 
		when SoldAsVacant = 'N' then 'No'
		else SoldAsVacant
		end
from PortfolioProject.dbo.Data_for_Data_Cleaning


update Data_for_Data_Cleaning 
set SoldAsVacant = case when SoldAsVacant = 'Y' then 'Yes'                                                      
		when SoldAsVacant = 'N' then 'No'
		else SoldAsVacant
		end



---------------------------------------------------------------------------------------------------------
-- Remove Duplicates

with RowNumCTE as(
select *,                                                                                       -- see duplicates in the table
	ROW_NUMBER() over (                                                                     -- "over" adds a unique number to every row
	partition by ParcelID,                                                                  -- split the rows into groups, where each group has the same values in the columns
				PropertyAddress,
				SalePrice,
				SaleDate,
				LegalReference
				order by UniqueID
				) row_num                                                       -- add a new column with amount of duplicates for each row

from PortfolioProject.dbo.Data_for_Data_Cleaning
)
delete                                                                                          -- remove duplicates
from RowNumCTE
where row_num > 1                                                                               -- the row must have at least 1 duplicate to be selected, so the first original row won't be updated
--order by ParcelID



---------------------------------------------------------------------------------------------------------
-- Delete Unused Columns

select *
from PortfolioProject.dbo.Data_for_Data_Cleaning

alter table PortfolioProject.dbo.Data_for_Data_Cleaning
drop column OwnerAddress, TaxDistrict, PropertyAddress
