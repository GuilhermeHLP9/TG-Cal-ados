ALTER TABLE "Order"
ADD CONSTRAINT "Order_quantity_positive" CHECK ("quantity" > 0);

ALTER TABLE "Order"
ADD CONSTRAINT "Order_price_per_pair_positive" CHECK ("pricePerPair" > 0);

ALTER TABLE "Order"
ADD CONSTRAINT "Order_total_price_positive" CHECK ("totalPrice" > 0);

ALTER TABLE "Order"
ADD CONSTRAINT "Order_material_cost_not_negative" CHECK ("materialCost" IS NULL OR "materialCost" >= 0);
