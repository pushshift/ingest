--
-- PostgreSQL database dump
--

CREATE TABLE bus_data (
    json jsonb
);

CREATE TABLE train_data (
    json jsonb
);
CREATE UNIQUE INDEX route_trip_vehicle_retrieved ON bus_data USING btree (((json ->> 'RouteID'::text)), ((json ->> 'TripID'::text)), ((json ->> 'VehicleID'::text)), (((json ->> 'retrieved_on'::text))::integer));
CREATE UNIQUE INDEX train_retrieved ON train_data USING btree (((json ->> 'TrainId'::text)), (((json ->> 'retrieved_on'::text))::integer));


--
-- PostgreSQL database dump complete
--

