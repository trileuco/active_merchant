# frozen_string_literal: true

require 'nokogiri'
require "net/http"

module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    class PaycometGateway < Gateway
      self.live_url = 'https://api.paycomet.com/gateway/xml-bankstore?wsdl'
      self.test_url = 'https://api.paycomet.com/gateway/xml-bankstore?wsdl'

      self.supported_countries = ['ES']
      self.default_currency = 'EUR'
      self.money_format        = :cents
      self.supported_cardtypes = %i[visa master american_express jcb diners_club unionpay]

      self.homepage_url        = 'https://www.paycomet.com/'
      self.display_name        = 'Paycomet'

      CURRENCY_CODES = %w[EUR USD GBP JPY].freeze

      # Copied from https://docs.paycomet.com/es/documentacion/codigos-de-error
      RESPONSE_TEXTS = {
        0 => 'Sin error',
        1 => 'Error',
        100 => 'Tarjeta caducada',
        101 => 'Tarjeta en lista negra',
        102 => 'Operación no permitida para el tipo de tarjeta',
        103 => 'Por favor, contacte con el banco emisor',
        104 => 'Error inesperado',
        105 => 'Crédito insuficiente para realizar el cargo',
        106 => 'Tarjeta no dada de alta o no registrada por el banco emisor',
        107 => 'Error de formato en los datos capturados. CodValid',
        108 => 'Error en el número de la tarjeta',
        109 => 'Error en FechaCaducidad',
        110 => 'Error en los datos',
        111 => 'Bloque CVC2 incorrecto',
        112 => 'Por favor, contacte con el banco emisor',
        113 => 'Tarjeta de crédito no válida',
        114 => 'La tarjeta tiene restricciones de crédito',
        115 => 'El emisor de la tarjeta no pudo identificar al propietario',
        116 => 'Pago no permitido en operaciones fuera de línea',
        118 => 'Tarjeta caducada. Por favor retenga físicamente la tarjeta',
        119 => 'Tarjeta en lista negra. Por favor retenga físicamente la tarjeta',
        120 => 'Tarjeta perdida o robada. Por favor retenga físicamente la tarjeta',
        121 => 'Error en CVC2. Por favor retenga físicamente la tarjeta',
        122 => 'Error en el proceso pre-transacción. Inténtelo más tarde',
        123 => 'Operación denegada. Por favor retenga físicamente la tarjeta',
        124 => 'Cierre con acuerdo',
        125 => 'Cierre sin acuerdo',
        126 => 'No es posible cerrar en este momento',
        127 => 'Parámetro no válido',
        128 => 'Las transacciones no fueron finalizadas',
        129 => 'Referencia interna duplicada',
        130 => 'Operación anterior no encontrada. No se pudo ejecutar la devolución',
        131 => 'Preautorización caducada',
        132 => 'Operación no válida con la moneda actual',
        133 => 'Error en formato del mensaje',
        134 => 'Mensaje no reconocido por el sistema',
        135 => 'Bloque CVC2 incorrecto',
        137 => 'Tarjeta no válida',
        138 => 'Error en mensaje de pasarela',
        139 => 'Error en formato de pasarela',
        140 => 'Tarjeta inexistente',
        141 => 'Cantidad cero o no válida',
        142 => 'Operación cancelada',
        143 => 'Error de autenticación',
        144 => 'Denegado debido al nivel de seguridad',
        145 => 'Error en el mensaje PUC. Contacte con PAYCOMET',
        146 => 'Error del sistema',
        147 => 'Transacción duplicada',
        148 => 'Error de MAC',
        149 => 'Liquidación rechazada',
        150 => 'Fecha/hora del sistema no sincronizada',
        151 => 'Fecha de caducidad no válida',
        152 => 'No se pudo encontrar la preautorización',
        153 => 'No se encontraron los datos solicitados',
        154 => 'No se puede realizar la operación con la tarjeta de crédito proporcionada',
        155 => 'Este método requiere la activación del protocolo VHASH',
        500 => 'Error inesperado',
        501 => 'Error inesperado',
        502 => 'Error inesperado',
        504 => 'Transacción cancelada previamente',
        505 => 'Transacción original denegada',
        506 => 'Datos de confirmación no válidos',
        507 => 'Error inesperado',
        508 => 'Transacción aún en proceso',
        509 => 'Error inesperado',
        510 => 'No es posible la devolución',
        511 => 'Error inesperado',
        512 => 'No es posible contactar con el banco emisor. Inténtelo más tarde',
        513 => 'Error inesperado',
        514 => 'Error inesperado',
        515 => 'Error inesperado',
        516 => 'Error inesperado',
        517 => 'Error inesperado',
        518 => 'Error inesperado',
        519 => 'Error inesperado',
        520 => 'Error inesperado',
        521 => 'Error inesperado',
        522 => 'Error inesperado',
        523 => 'Error inesperado',
        524 => 'Error inesperado',
        525 => 'Error inesperado',
        526 => 'Error inesperado',
        527 => 'Tipo de transacción desconocido',
        528 => 'Error inesperado',
        529 => 'Error inesperado',
        530 => 'Error inesperado',
        531 => 'Error inesperado',
        532 => 'Error inesperado',
        533 => 'Error inesperado',
        534 => 'Error inesperado',
        535 => 'Error inesperado',
        536 => 'Error inesperado',
        537 => 'Error inesperado',
        538 => 'Operación no cancelable',
        539 => 'Error inesperado',
        540 => 'Error inesperado',
        541 => 'Error inesperado',
        542 => 'Error inesperado',
        543 => 'Error inesperado',
        544 => 'Error inesperado',
        545 => 'Error inesperado',
        546 => 'Error inesperado',
        547 => 'Error inesperado',
        548 => 'Error inesperado',
        549 => 'Error inesperado',
        550 => 'Error inesperado',
        551 => 'Error inesperado',
        552 => 'Error inesperado',
        553 => 'Error inesperado',
        554 => 'Error inesperado',
        555 => 'No se pudo encontrar la operación previa',
        556 => 'Inconsistencia de datos en la validación de la cancelación',
        557 => 'El pago diferido no existe',
        558 => 'Error inesperado',
        559 => 'Error inesperado',
        560 => 'Error inesperado',
        561 => 'Error inesperado',
        562 => 'La tarjeta no admite preautorizaciones',
        563 => 'Inconsistencia de datos en confirmación',
        564 => 'Error inesperado',
        565 => 'Error inesperado',
        567 => 'Operación de devolución no definida correctamente',
        568 => 'Comunicación online incorrecta',
        569 => 'Operación denegada',
        1000 => 'Cuenta no encontrada. Revise su configuración',
        1001 => 'Usuario no encontrado. Contacte con PAYCOMET',
        1002 => 'Error en respuesta de pasarela. Contacte con PAYCOMET',
        1003 => 'Firma no válida. Por favor, revise su configuración',
        1004 => 'Acceso no permitido',
        1005 => 'Formato de tarjeta de crédito no válido',
        1006 => 'Error en el campo Código de Validación',
        1007 => 'Error en el campo Fecha de Caducidad',
        1008 => 'Referencia de preautorización no encontrada',
        1009 => 'Datos de preautorización no encontrados',
        1010 => 'No se pudo enviar la devolución. Por favor reinténtelo más tarde',
        1011 => 'No se pudo conectar con el host',
        1012 => 'No se pudo resolver el proxy',
        1013 => 'No se pudo resolver el host',
        1014 => 'Inicialización fallida',
        1015 => 'No se ha encontrado el recurso HTTP',
        1016 => 'El rango de opciones no es válido para la transferencia HTTP',
        1017 => 'No se construyó correctamente el POST',
        1018 => 'El nombre de usuario no se encuentra bien formateado',
        1019 => 'Se agotó el tiempo de espera en la petición',
        1020 => 'Sin memoria',
        1021 => 'No se pudo conectar al servidor SSL',
        1022 => 'Protocolo no soportado',
        1023 => 'La URL dada no está bien formateada y no puede usarse',
        1024 => 'El usuario en la URL se formateó de manera incorrecta',
        1025 => 'No se pudo registrar ningún recurso disponible para completar la operación',
        1026 => 'Referencia externa duplicada',
        1027 => 'El total de las devoluciones no puede superar la operación original',
        1028 => 'La cuenta no se encuentra activa. Contacte con PAYCOMET',
        1029 => 'La cuenta no se encuentra certificada. Contacte con PAYCOMET',
        1030 => 'El producto está marcado para eliminar y no puede ser utilizado',
        1031 => 'Permisos insuficientes',
        1032 => 'El producto no puede ser utilizado en el entorno de pruebas',
        1033 => 'El producto no puede ser utilizado en el entorno de producción',
        1034 => 'No ha sido posible enviar la petición de devolución',
        1035 => 'Error en el campo IP de origen de la operación',
        1036 => 'Error en formato XML',
        1037 => 'El elemento raíz no es correcto',
        1038 => 'Campo DS_MERCHANT_AMOUNT incorrecto',
        1039 => 'Campo DS_MERCHANT_ORDER incorrecto',
        1040 => 'Campo DS_MERCHANT_MERCHANTCODE incorrecto',
        1041 => 'Campo DS_MERCHANT_CURRENCY incorrecto',
        1042 => 'Campo DS_MERCHANT_PAN incorrecto',
        1043 => 'Campo DS_MERCHANT_CVV2 incorrecto',
        1044 => 'Campo DS_MERCHANT_TRANSACTIONTYPE incorrecto',
        1045 => 'Campo DS_MERCHANT_TERMINAL incorrecto',
        1046 => 'Campo DS_MERCHANT_EXPIRYDATE incorrecto',
        1047 => 'Campo DS_MERCHANT_MERCHANTSIGNATURE incorrecto',
        1048 => 'Campo DS_ORIGINAL_IP incorrecto',
        1049 => 'No se encuentra el cliente',
        1050 => 'La nueva cantidad a preautorizar no puede superar la cantidad de la preautorización original',
        1099 => 'Error inesperado',
        1100 => 'Limite diario por tarjeta excedido',
        1103 => 'Error en el campo ACCOUNT',
        1104 => 'Error en el campo USERCODE',
        1105 => 'Error en el campo TERMINAL',
        1106 => 'Error en el campo OPERATION',
        1107 => 'Error en el campo REFERENCE',
        1108 => 'Error en el campo AMOUNT',
        1109 => 'Error en el campo CURRENCY',
        1110 => 'Error en el campo SIGNATURE',
        1120 => 'Operación no disponible',
        1121 => 'No se encuentra el cliente',
        1122 => 'Usuario no encontrado. Contacte con PAYCOMET',
        1123 => 'Firma no válida. Por favor, revise su configuración',
        1124 => 'Operación no disponible con el usuario especificado',
        1125 => 'Operación no válida con una moneda distinta del Euro',
        1127 => 'Cantidad cero o no válida',
        1128 => 'Conversión de la moneda actual no válida',
        1129 => 'Cantidad no válida',
        1130 => 'No se encuentra el producto',
        1131 => 'Operación no válida con la moneda actual',
        1132 => 'Operación no válida con una moneda distinta del Euro',
        1133 => 'Información del botón corrupta',
        1134 => 'La subscripción no puede ser mayor de la fecha de caducidad de la tarjeta',
        1135 => 'DS_EXECUTE no puede ser true si DS_SUBSCRIPTION_STARTDATE es diferente de hoy.',
        1136 => 'Error en el campo PAYTPV_OPERATIONS_MERCHANTCODE',
        1137 => 'PAYTPV_OPERATIONS_TERMINAL debe ser Array',
        1138 => 'PAYTPV_OPERATIONS_OPERATIONS debe ser Array',
        1139 => 'Error en el campo PAYTPV_OPERATIONS_SIGNATURE',
        1140 => 'No se encuentra alguno de los PAYTPV_OPERATIONS_TERMINAL',
        1141 => 'Error en el intervalo de fechas solicitado',
        1142 => 'La solicitud no puede tener un intervalo mayor a 2 años',
        1143 => 'El estado de la operación es incorrecto',
        1144 => 'Error en los importes de la búsqueda',
        1145 => 'El tipo de operación solicitado no existe',
        1146 => 'Tipo de ordenación no reconocido',
        1147 => 'PAYTPV_OPERATIONS_SORTORDER no válido',
        1148 => 'Fecha de inicio de suscripción errónea',
        1149 => 'Fecha de final de suscripción errónea',
        1150 => 'Error en la periodicidad de la suscripción',
        1151 => 'Falta el parámetro usuarioXML',
        1152 => 'Falta el parámetro codigoCliente',
        1153 => 'Falta el parámetro usuarios',
        1154 => 'Falta el parámetro firma',
        1155 => 'El parámetro usuarios no tiene el formato correcto',
        1156 => 'Falta el parámetro type',
        1157 => 'Falta el parámetro name',
        1158 => 'Falta el parámetro surname',
        1159 => 'Falta el parámetro email',
        1160 => 'Falta el parámetro password',
        1161 => 'Falta el parámetro language',
        1162 => 'Falta el parámetro maxamount o su valor no puede ser 0',
        1163 => 'Falta el parámetro multicurrency',
        1165 => 'El parámetro permissions_specs no tiene el formato correcto',
        1166 => 'El parámetro permissions_products no tiene el formato correcto',
        1167 => 'El parámetro email no parece una dirección válida',
        1168 => 'El parámetro password no tiene la fortaleza suficiente',
        1169 => 'El valor del parámetro type no está admitido',
        1170 => 'El valor del parámetro language no está admitido',
        1171 => 'El formato del parámetro maxamount no está permitido',
        1172 => 'El valor del parámetro multicurrency no está admitido',
        1173 => 'El valor del parámetro permission_id - permissions_specs no está admitido',
        1174 => 'No existe el usuario',
        1175 => 'El usuario no tiene permisos para acceder al método altaUsario',
        1176 => 'No se encuentra la cuenta de cliente',
        1177 => 'No se pudo cargar el usuario de la cuenta',
        1178 => 'La firma no es correcta',
        1179 => 'No existen productos asociados a la cuenta',
        1180 => 'El valor del parámetro product_id - permissions_products no está autorizado',
        1181 => 'El valor del parámetro permission_id -permissions_products no está admitido',
        1185 => 'Límite mínimo por operación no permitido',
        1186 => 'Límite máximo por operación no permitido',
        1187 => 'Límite máximo diario no permitido',
        1188 => 'Límite máximo mensual no permitido',
        1189 => 'Cantidad máxima por tarjeta / 24h. no permitida',
        1190 => 'Cantidad máxima por tarjeta / 24h. / misma dirección IP no permitida',
        1191 => 'Límite de transacciones por dirección IP /día (diferentes tarjetas) no permitido',
        1192 => 'País no admitido (dirección IP del cliente)',
        1193 => 'Tipo de tarjeta (crédito / débito) no admitido',
        1194 => 'Marca de la tarjeta no admitida',
        1195 => 'Categoría de la tarjeta no admitida',
        1196 => 'Transacción desde país distinto al emisor de la tarjeta no admitida',
        1197 => 'Operación denegada. Filtro país emisor de la tarjeta no admitido',
        1198 => 'Superado el límite de scoring',
        1200 => 'Operación denegada. Filtro misma tarjeta, distinto país en las últimas 24 horas',
        1201 => 'Número de intentos consecutivos erróneos con la misma tarjeta excedidos',
        1202 => 'Número de intentos fallidos (últimos 30 minutos) desde la misma dirección ip excedidos',
        1203 => 'Las credenciales no son válidas o no están configuradas',
        1204 => 'Recibido token incorrecto',
        1205 => 'No ha sido posible realizar la operación',
        1206 => 'providerID no disponible',
        1207 => 'Falta el parámetro operaciones o no tiene el formato correcto',
        1208 => 'Falta el parámetro paycometMerchant',
        1209 => 'Falta el parámetro merchatID',
        1210 => 'Falta el parámetro terminalID',
        1211 => 'Falta el parámetro tpvID',
        1212 => 'Falta el parámetro operationType',
        1213 => 'Falta el parámetro operationResult',
        1214 => 'Falta el parámetro operationAmount',
        1215 => 'Falta el parámetro operationCurrency',
        1216 => 'Falta el parámetro operationDatetime',
        1217 => 'Falta el parámetro originalAmount',
        1218 => 'Falta el parámetro pan',
        1219 => 'Falta el parámetro expiryDate',
        1220 => 'Falta el parámetro reference',
        1221 => 'Falta el parámetro signature',
        1222 => 'Falta el parámetro originalIP o no tiene el formato correcto',
        1223 => 'Falta el parámetro authCode o errorCode',
        1224 => 'No se encuentra el producto de la operación',
        1225 => 'El tipo de la operación no está admitido',
        1226 => 'El resultado de la operación no está admitido',
        1227 => 'La moneda de la operación no está admitida',
        1228 => 'La fecha de la operación no tiene el formato correcto',
        1229 => 'La firma no es correcta',
        1230 => 'No se encuentra información de la cuenta asociada',
        1231 => 'No se encuentra información del producto asociado',
        1232 => 'No se encuentra información del usuario asociado',
        1233 => 'El producto no está configurado como multimoneda',
        1234 => 'La cantidad de la operación no tiene el formato correcto',
        1235 => 'La cantidad original de la operación no tiene el formato correcto',
        1236 => 'La tarjeta no tiene el formato correcto',
        1237 => 'La fecha de caducidad de la tarjeta no tiene el formato correcto',
        1238 => 'No puede inicializarse el servicio',
        1239 => 'No puede inicializarse el servicio',
        1240 => 'Método no implementado',
        1241 => 'No puede inicializarse el servicio',
        1242 => 'No puede finalizarse el servicio',
        1243 => 'Falta el parámetro operationCode',
        1244 => 'Falta el parámetro bankName',
        1245 => 'Falta el parámetro csb',
        1246 => 'Falta el parámetro userReference',
        1247 => 'No se encuentra el FUC enviado',
        1248 => 'Referencia externa duplicada. Operación en curso.',
        1249 => 'No se encuentra el parámetro [DS_]AGENT_FEE',
        1250 => 'El parámetro [DS_]AGENT_FEE no tienen el formato correcto',
        1251 => 'El parámetro DS_AGENT_FEE no es correcto',
        1252 => 'No se encuentra el parámetro CANCEL_URL',
        1253 => 'El parámetro CANCEL_URL no es correcto',
        1254 => 'Comercio con titular seguro y titular sin clave de compra segura',
        1255 => 'Llamada finalizada por el cliente',
        1256 => 'Llamada finalizada, intentos incorrectos excedidos',
        1257 => 'Llamada finalizada, intentos de operación excedidos',
        1258 => 'stationID no disponible',
        1259 => 'No ha sido posible establecer la sesión IVR',
        1260 => 'Falta el parámetro merchantCode',
        1261 => 'El parámetro merchantCode no es correcto',
        1262 => 'Falta el parámetro terminalIDDebtor',
        1263 => 'Falta el parámetro terminalIDCreditor',
        1264 => 'No dispone de permisos para realizar la operación',
        1265 => 'La cuenta Iban (terminalIDDebtor) no es válida',
        1266 => 'La cuenta Iban (terminalIDCreditor) no es válida',
        1267 => 'El BicCode de la cuenta Iban (terminalIDDebtor) no es válido',
        1268 => 'El BicCode de la cuenta Iban (terminalIDCreditor) no es válido',
        1269 => 'Falta el parámetro operationOrder',
        1270 => 'El parámetro operationOrder no tiene el formato correcto',
        1271 => 'El parámetro operationAmount no tiene el formato correcto',
        1272 => 'El parámetro operationDatetime no tiene el formato correcto',
        1273 => 'El parámetro operationConcept contiene caracteres inválidos o excede de 140 caracteres',
        1274 => 'No ha sido posible grabar la operación SEPA',
        1275 => 'No ha sido posible grabar la operación SEPA',
        1276 => 'No ha sido posible generar un token de operación',
        1277 => 'Valor de scoring no válido',
        1278 => 'El formato del parámetro idioma no es correcto',
        1279 => 'El formato del Titular de la tarjeta no es correcto',
        1280 => 'El número de tarjeta no es correcto',
        1281 => 'El formato del mes no es correcto',
        1282 => 'El formato del año no es correcto',
        1283 => 'El formato del cvc2 no es correcto',
        1284 => 'El formato del parámetro JETID no es correcto',
        1288 => 'Parámetro splitId no válido',
        1289 => 'Parámetro splitId no autorizado',
        1290 => 'Este terminal no permite (split) transfers',
        1291 => 'No ha sido posible grabar la operación (split) transfer',
        1292 => 'La fecha de la operación original no puede superar 90 días',
        1293 => '(Split) Transfer original no encontrada',
        1294 => 'El total de las revocaciones no puede superar el (split) transfer original',
        1295 => 'No ha sido posible grabar la operación (split) transfer reversal',
        1296 => 'Falta el parámetro uniqueIdCreditor',
        1297 => 'La cuenta bancaria no está certificada.',
        1298 => 'Falta el parámetro companyNameCreditor.',
        1299 => 'El parámetro companyNameCreditor no es válido.',
        1300 => 'El parámetro swiftCodeCreditor no es válido.',
        1301 => 'Se ha excedido el número de operaciones por petición.',
        1302 => 'Operación denegada. Filtro límite de operaciones por IP últimas 24 horas.',
        1303 => 'Operación denegada. Filtro acumulado importe por IP últimas 24 horas.',
        1304 => 'La cuenta no está configurada correctamente.',
        1305 => 'Falta el parámetro merchantCustomerId.',
        1306 => 'El parámetro merchantCustomerIban no es válido.',
        1307 => 'Falta el parámetro fileContent.',
        1308 => 'Extensión de documento no válida.',
        1309 => 'El documento excede el tamaño máximo.',
        1310 => 'El tipo de documento no es válido.',
        1311 => 'Límite de operaciones por referencia / diferente IP no permitido',
        1312 => 'Operación SEPA Credit Transfer denegada',
        1313 => 'No existe payment_info',
        1314 => 'El tipo de cuenta bancaria no es IBAN',
        1315 => 'No se han encontrado documentos',
        1316 => 'Error en la subida de documentos',
        1317 => 'Error en la descarga de documentos',
        1318 => 'La documentación requerida está incompleta',
        1319 => 'No permitido. La moneda no es EUR',
        1320 => 'El estado de la factura no es COMPLETE',
        1321 => 'La excepción enviada no esta habilitada',
        1322 => 'Se requiere challenge para finalizar la operación',
        1323 => 'La información obligatoria del MERCHANT_DATA no se ha enviado',
        1324 => 'El parámetro DS_USER_INTERACTION no es válido',
        1325 => 'Challenge requerido y usuario no presente',
        1326 => 'Denegación por controles de seguridad en el procesador',
        1327 => 'Datos de operación EMV3DS incorrectos o no indicados',
        1328 => 'Error en la recepción de parámetros: debe ser EMAIL o SMS',
        1329 => 'Ha fallado el envío del email',
        1330 => 'Ha fallado el envío del SMS',
        1331 => 'Plantilla no encontrada',
        1332 => 'Alcanzado límite de peticiones por minuto',
        1333 => 'Móvil no configurado para el envío de SMS en Sandbox',
        1334 => 'Email no configurado para el envío de Emails en Sandbox',
        1335 => 'No se encuentra el parámetro DS_MERCHANT_IDENTIFIER',
        1336 => 'El parámetro DS_MERCHANT_IDENTIFIER no es correcto',
        1337 => 'Ruta de notificación no configurada',
        1338 => 'Ruta de notificación no responde correctamente',
        1339 => 'Configuración de terminales incorrecta',
        1340 => 'Método de pago no disponible',
        1341 => 'Operación por DCC no disponible',
        1400 => 'Bizum no ha podido autenticar el usuario'
      }.freeze

      # Creates a new instance
      #
      # ==== Options
      #
      # * <tt>:login</tt> -- The Paycomet Client Code (REQUIRED)
      # * <tt>:secret_key</tt> -- The Paycomet Password. (REQUIRED)
      # * <tt>:terminal</tt> -- The Paycomet Terminal. Defaults to 1. (OPTIONAL)
      # * <tt>:ip</tt> -- The original IP. Defaults to 1. (OPTIONAL)
      # * <tt>:jet_id</tt> -- The Paycomet jetId. (OPTIONAL)
      # * <tt>:test</tt> -- +true+ or +false+. Defaults to +false+. (OPTIONAL)
      def initialize(options = {})
        requires!(options, :login, :secret_key, :terminal, :ip)
        super
      end

      def add_user(user_payment_token, options = {})
        data = options.clone

        add_action(data, :add_user)
        add_payment(data, user_payment_token)

        commit(data)
      end

      def add_user_token(jetToken, options = {})
        data = options.clone

        add_action(data, :add_user_token)
        data[:jet_token] = jetToken
        commit(data)
      end

      def info_user(user_payment_token, options = {})
        data = options.clone

        add_action(data, :info_user)
        add_payment(data, user_payment_token)

        commit(data)
      end

      def remove_user(user_payment_token, options = {})
        data = options.clone

        add_action(data, :remove_user)
        add_payment(data, user_payment_token)

        commit(data)
      end

      def purchase(money, user_payment_token, options = {})
        requires!(options, :order_id)
        data = options.clone

        add_action(data, :execute_purchase)
        add_payment(data, user_payment_token)
        add_amount(data, money)

        commit(data)
      end

      def authorize(money, user_payment_token, options = {})
        requires!(options, :order_id)
        data = options.clone

        add_action(data, :create_preauthorization)
        add_payment(data, user_payment_token)
        add_amount(data, money)

        commit(data)
      end

      def capture(money, authorization, options = {})
        requires!(options, :user_payment_token)
        data = options.clone

        add_action(data, :preauthorization_confirm)
        add_payment(data, data[:user_payment_token])
        add_order_authorization(data, authorization)
        add_amount(data, money)

        commit(data)
      end

      def void(authorization, options = {})
        requires!(options, :user_payment_token, :amount)
        data = options.clone

        add_action(data, :preauthorization_cancel)
        add_payment(data, data[:user_payment_token])
        add_order_authorization(data, authorization)
        add_amount(data, data[:amount])

        commit(data)
      end

      def refund(money, authorization, options = {})
        requires!(options, :user_payment_token)
        data = options.clone

        add_action(data, :execute_refund)
        add_amount(data, money)
        add_payment(data, data[:user_payment_token])
        add_order_authorization(data, authorization)

        commit(data)
      end

      def verify(payment, options = {})
        MultiResponse.run(:use_first_response) do |r|
          r.process { authorize(100, payment, options) }
          r.process(:ignore_result) { void(r.authorization, options) }
        end
      end

      def supports_scrubbing
        true
      end

      def scrub(transcript)
        transcript
          .gsub(%r((Authorization: Basic )\w+), '\1[FILTERED]')
          .gsub(%r((<CardNumber>)[^<]+(<))i, '\1[FILTERED]\2')
          .gsub(%r((<DS_TOKEN_USER>)[^<]+(<))i, '\1[FILTERED]\2')
          .gsub(%r((<DS_MERCHANT_JETTOKEN>)[^<]+(<))i, '\1[FILTERED]\2')
          .gsub(%r((<DS_MERCHANT_AUTHCODE>)[^<]+(<))i, '\1[FILTERED]\2')
          .gsub(%r((<DS_MERCHANT_PAN>)[^<]+(<))i, '\1[FILTERED]\2')
          .gsub(%r((<DS_MERCHANT_CVV2>)[^<]+(<))i, '\1[FILTERED]\2')
      end

      private

      def url
        test? ? test_url : live_url
      end

      def add_action(data, action)
        data[:action] = action
      end

      def add_amount(data, money)
        data[:amount] = amount(money).to_s
        data[:currency] = currency_code(data[:currency] || currency(money))
      end

      def add_payment(data, payment_method)
        if payment_method.is_a?(String)
          add_user_authorization(data, payment_method)
        else
          data[:card] = {
            pan: payment_method.number,
            date: "#{format(payment_method.year, :two_digits)}#{format(payment_method.month, :two_digits)}",
            cvv: payment_method.verification_value
          }
        end
      end

      def add_user_authorization(data, authorization)
        user_id, credit_card_token = split_authorization(authorization)
        data[:user_id] = user_id
        data[:credit_card_token] = credit_card_token
      end


      def add_order_authorization(data, authorization)
        order_id, auth_code = split_authorization(authorization)
        data[:order_id] = order_id
        data[:auth_code] = auth_code
      end

      def commit(data)
        action = data[:action]
        parse(ssl_post(url, merchant_data_xml(data), headers(action)), action)
      end

      def headers(action=nil)
        if action
          {
            'Content-Type' => 'text/xml',
            'SOAPAction' => action.to_s
          }
        else
          {
            'Content-Type' => 'application/x-www-form-urlencoded'
          }
        end
      end

      def build_signature(data)
        str = if [:execute_purchase, :create_preauthorization].include?(data[:action])
          @options[:login] + data[:user_id] + data[:credit_card_token] + @options[:terminal] + data[:amount] + data[:order_id] + @options[:secret_key]
        elsif [:preauthorization_confirm, :preauthorization_cancel].include?(data[:action])
          @options[:login] + data[:user_id] + data[:credit_card_token] + @options[:terminal] + data[:order_id] + data[:amount] + @options[:secret_key]
        elsif :execute_refund == data[:action]
          @options[:login] + data[:user_id] + data[:credit_card_token] + @options[:terminal] + data[:auth_code] + data[:order_id] + @options[:secret_key]
        elsif :add_user == data[:action]
          @options[:login] + data[:card][:pan] + data[:card][:cvv] + @options[:terminal] + @options[:secret_key]
        elsif :add_user_token == data[:action]
           @options[:login] + data[:jet_token] + @options[:jet_id] + @options[:terminal] + @options[:secret_key]
        elsif [:info_user, :remove_user].include?(data[:action])
          @options[:login] + data[:user_id] + data[:credit_card_token] + @options[:terminal] + @options[:secret_key]
        else
          ""
        end
        Digest::SHA512.hexdigest(str)
      end

      def merchant_data_xml(data)
        xml = Builder::XmlMarkup.new indent: 2
        build_merchant_data(xml, data)
        xml.target!
      end

      def build_merchant_data(xml, data)
        xml.tag!("SOAP-ENV:Envelope", {"xmlns:SOAP-ENV"=>"http://schemas.xmlsoap.org/soap/envelope/"}) do
          xml.tag!("SOAP-ENV:Header")
          xml.tag!("SOAP-ENV:Body") do
            xml.tag!(data[:action]) do
              xml.DS_MERCHANT_TERMINAL @options[:terminal] unless @options[:terminal].blank?
              xml.DS_MERCHANT_MERCHANTCODE @options[:login] unless @options[:login].blank?
              xml.DS_ORIGINAL_IP @options[:ip] unless @options[:ip].blank?
              xml.DS_MERCHANT_JETID @options[:jet_id] unless @options[:jet_id].blank?
              xml.DS_MERCHANT_MERCHANTSIGNATURE build_signature(data)

              xml.DS_MERCHANT_CURRENCY data[:currency] unless data[:currency].blank?
              xml.DS_MERCHANT_AMOUNT data[:amount] unless data[:amount].blank?
              xml.DS_MERCHANT_ORDER data[:order_id] unless data[:order_id].blank?
              xml.DS_MERCHANT_JETTOKEN data[:jet_token] unless data[:jet_token].blank?
              xml.DS_IDUSER data[:user_id] unless data[:user_id].blank?
              xml.DS_TOKEN_USER data[:credit_card_token] unless data[:credit_card_token].blank?
              xml.DS_MERCHANT_AUTHCODE data[:auth_code] unless data[:auth_code].blank?

              if data[:card]
                xml.DS_MERCHANT_PAN data[:card][:pan] unless data[:card][:pan].blank?
                xml.DS_MERCHANT_EXPIRYDATE data[:card][:date] unless data[:card][:date].blank?
                xml.DS_MERCHANT_CVV2 data[:card][:cvv] unless data[:card][:cvv].blank?
              end

              xml.DS_MERCHANT_PRODUCTDESCRIPTION data[:description] unless data[:description].blank?
              xml.DS_MERCHANT_OWNER data[:owner] unless data[:owner].blank?
              xml.DS_MERCHANT_SCORING data[:scoring] unless data[:scoring].blank?
              xml.DS_MERCHANT_DATA data[:client_data] unless data[:client_data].blank?
              xml.DS_MERCHANT_MERCHANTDESCRIPTOR data[:merchant_descriptor] unless data[:merchant_descriptor].blank?
              xml.DS_MERCHANT_SCA_EXCEPTION data[:sca_exception] unless data[:sca_exception].blank?
              xml.DS_MERCHANT_TRX_TYPE data[:trx_type] unless data[:trx_type].blank?
              xml.DS_ESCROW_TARGETS data[:escrow_targets] unless data[:escrow_targets].blank?
              xml.DS_USER_INTERACTION data[:user_interaction] unless data[:user_interaction].blank?
            end
          end
        end
      end

      def parse(data, action)
        params  = {}
        success = false
        message = ''
        options = @options.merge(test: test?)
        xml     = Nokogiri::XML(data)
        code = xml.xpath("//SOAP-ENV:Envelope/SOAP-ENV:Body/SOAP-ENV:#{action}Response/DS_ERROR_ID").text
        message = response_text(code.to_i)

        if code == '0'
          success = true
          op = xml.xpath("//SOAP-ENV:Envelope/SOAP-ENV:Body/SOAP-ENV:#{action}Response")
          op.children.each do |element|
            params[element.name.downcase.to_sym] = element.text
          end
          options[:authorization] = build_authorization(params)
        else
          options[:error_code] = code.to_i
        end

        Response.new(success, message, params, options)
      end

      def build_authorization(params)
        if params[:ds_iduser] && params[:ds_token_user]
          return [params[:ds_iduser], params[:ds_token_user]].join('|')
        elsif params[:ds_merchant_order] && params[:ds_merchant_authcode]
          return [params[:ds_merchant_order], params[:ds_merchant_authcode]].join('|')
        end
        ''
      end

      def split_authorization(authorization)
        authorization.split('|')
      end

      def currency_code(currency)
        return currency if /^\d+$/.match?(currency)
        raise ArgumentError, "Unknown currency #{currency}" unless CURRENCY_CODES.include? currency

        currency
      end

      def response_text(code)
        code = code.to_i
        code = 0 if code < 100
        RESPONSE_TEXTS[code] || 'Unkown code, please check in manual'
      end

      def is_success_response?(code)
        (code.to_i < 100) || [400, 481, 500, 900].include?(code.to_i)
      end

    end
  end
end
