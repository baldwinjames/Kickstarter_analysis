--A quick review through the data to get a sense of what's there and to make sure the import worked
SELECT * FROM campaign LIMIT 10;
SELECT * FROM category LIMIT 10;
SELECT * FROM sub_category LIMIT 10;
SELECT * FROM currency LIMIT 10;
SELECT * FROM country LIMIT 10;

--Since we're reviewing financial data, I'm going to convert everything into USD.
ALTER TABLE currency
ADD COLUMN USD_Conversion NUMERIC;

--We're only dealing with about a dozens sets of currencies and we're only doing this as a one-off, so no need for dynamic values.
UPDATE currency
SET USD_Conversion = 1.26
WHERE currency.name = 'GBP';

--A quick double-check to make sure everything works the way I want
SELECT * FROM currency;

--I realized I can manually set the values in the PostgreSQL output, so the remaining currencies were updated that way

--Since I'm going to likely run quite a few queries with this data, I'm going to add it to the main campaign table
ALTER TABLE campaign
ADD COLUMN Pledged_USD NUMERIC,
ADD COLUMN Goal_USD NUMERIC;

--Now to update the new fields with the converted values
UPDATE campaign
SET 
    pledged_usd = pledged * (SELECT usd_conversion FROM currency WHERE currency.id = campaign.currency_id),
    goal_usd = goal * (SELECT usd_conversion FROM currency WHERE currency.id = campaign.currency_id);

--A final check to make sure it all looks good
SELECT * FROM campaign LIMIT 10;
