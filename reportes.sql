CREATE OR REPLACE FUNCTION public.reporte1(configID int, droneID int) RETURNS double precision AS $$
DECLARE 
	duracion double precision;
	volumen double precision;
BEGIN
	SELECT configuraciones.volumen_descarga INTO STRICT volumen FROM public.configuraciones WHERE id = configID AND drone = droneID;
	SELECT drones.duracion_bateria INTO STRICT duracion FROM public.drones WHERE id = droneID;
	RETURN duracion * volumen;
END;
$$ LANGUAGE plpgsql;