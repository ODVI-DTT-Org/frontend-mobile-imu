// DataService.ts - Service to handle CSV data integration

export interface Client {
  ClientID: number;
  FullName: string;
  ProductType: string;
  MarketType: string;
  ClientType: string;
  PensionType: string;
  PAN: string;
  Age: number;
  Birthday: string;
  Gmail: string;
  FacebookLink: string;
}

export interface Address {
  AddressID: number;
  ClientID: number;
  Street: string;
  Municipality: string;
  Province: string;
  IsDefault: boolean;
}

export interface PhoneNumber {
  PhoneID: number;
  ClientID: number;
  PhoneNumber: string;
  IsPrimary: boolean;
}

export interface Visit {
  VisitID: number;
  ClientID: number;
  DateOfVisit: string;
  Address: string;
  Touchpoint: number;
  TouchpointType: string;
  ClientType: string;
  Reason: string;
  TimeArrival: string;
  OdometerArrival: string;
  TimeDeparture: string;
  OdometerDeparture: string;
  NextVisitDate: string;
  Remarks: string;
}

export interface Caravan {
  CaravanID: number;
  FullName: string;
  IsActive: boolean;
}

export interface CaravanClient {
  CaravanClientID: number;
  CaravanID: number;
  ClientID: number;
  AssignedDate: string;
  IsActive: boolean;
}

export interface ClientDetails extends Client {
  addresses: Address[];
  phoneNumbers: PhoneNumber[];
  visits: Visit[];
  currentReason?: string;
  isInterested?: boolean;
  caravan?: Caravan;
}

// Caravan data - Marketing Representatives
const caravansData: Caravan[] = [
  { CaravanID: 1, FullName: "MELCHOR QUINTO", IsActive: true },
  { CaravanID: 2, FullName: "ABELARDO NUQUI", IsActive: true },
  { CaravanID: 3, FullName: "CHRISTOPHER DELACRUZ", IsActive: true },
  { CaravanID: 4, FullName: "GODWIN RUIZ", IsActive: true },
  { CaravanID: 5, FullName: "HILARIO JR. GARCIA", IsActive: true },
  { CaravanID: 6, FullName: "JONNEL MANIO", IsActive: true },
  { CaravanID: 7, FullName: "JAN NIÑO BOI F. URBANO", IsActive: true },
  { CaravanID: 8, FullName: "MARK DEL MORO", IsActive: true },
  { CaravanID: 9, FullName: "MARIO RESURRECION", IsActive: true },
  { CaravanID: 10, FullName: "MARK ANTHONY ALVAREZ", IsActive: true },
  { CaravanID: 11, FullName: "BOYNEIL MALIWAT", IsActive: true },
  { CaravanID: 12, FullName: "DARWIN MAGTANGOB", IsActive: true },
  { CaravanID: 13, FullName: "ERVEN ESPELIMBERGO", IsActive: true },
  { CaravanID: 14, FullName: "EDWARD SEVILLENA", IsActive: true },
  { CaravanID: 15, FullName: "JOHNSON BERCE", IsActive: true },
  { CaravanID: 16, FullName: "JORIS LUCILO", IsActive: true },
  { CaravanID: 17, FullName: "JOEL OPLE", IsActive: true },
  { CaravanID: 18, FullName: "ROLAND ODI", IsActive: true },
  { CaravanID: 19, FullName: "RICARDO C. VERDE", IsActive: true },
  { CaravanID: 20, FullName: "NOLAN DELROSARIO", IsActive: true },
  { CaravanID: 21, FullName: "FRANCIS NIEL DULLER", IsActive: true },
  { CaravanID: 22, FullName: "HARVEY C. TORREFIEL", IsActive: true },
  { CaravanID: 23, FullName: "JOSEPH RAFAEL GARCIA", IsActive: true },
  { CaravanID: 24, FullName: "MARK KEVIN GERMAN", IsActive: true },
  { CaravanID: 25, FullName: "MARLON DEBORDE", IsActive: true },
  { CaravanID: 26, FullName: "YURI FABRID", IsActive: true },
  { CaravanID: 27, FullName: "ALEXANDER JR. AVENIDO", IsActive: true },
  { CaravanID: 28, FullName: "ALBERTO ANACIO", IsActive: true },
  { CaravanID: 29, FullName: "JONYBOY GERONCA", IsActive: true },
  { CaravanID: 30, FullName: "NILO LOPEZ", IsActive: true },
  { CaravanID: 31, FullName: "ROWEL PALAMOS", IsActive: true },
  { CaravanID: 32, FullName: "ROLANDO SARMIENTO JR.", IsActive: true },
  { CaravanID: 33, FullName: "RAMSES RANADA", IsActive: true },
  { CaravanID: 34, FullName: "PETER PAUL CELESTE", IsActive: true },
  { CaravanID: 35, FullName: "AERON ANGELES", IsActive: true },
  { CaravanID: 36, FullName: "GLENNMAR CALAIN", IsActive: true },
  { CaravanID: 37, FullName: "JEFFREY HECHANOVA", IsActive: true },
  { CaravanID: 38, FullName: "JOHN RAY SINGSON", IsActive: true },
  { CaravanID: 39, FullName: "KENNY-LYN AVILA", IsActive: true },
  { CaravanID: 40, FullName: "NECOLUID QUIOKELES", IsActive: true },
  { CaravanID: 41, FullName: "GEOFFREY MORENO", IsActive: true },
  { CaravanID: 42, FullName: "ARCHIE SUMAGANG", IsActive: true },
  { CaravanID: 43, FullName: "GEORGE REMOLADO", IsActive: true },
  { CaravanID: 44, FullName: "MARVIN BALANUECO", IsActive: true },
  { CaravanID: 45, FullName: "EDWIN MANGAY-AYAM", IsActive: true }
];

// Caravan-Client assignments
const caravanClientsData: CaravanClient[] = [
  { CaravanClientID: 1, CaravanID: 1, ClientID: 1, AssignedDate: "2024-01-15", IsActive: true },
  { CaravanClientID: 2, CaravanID: 1, ClientID: 15, AssignedDate: "2024-01-20", IsActive: true },
  { CaravanClientID: 3, CaravanID: 1, ClientID: 21, AssignedDate: "2024-02-01", IsActive: true },
  { CaravanClientID: 4, CaravanID: 2, ClientID: 2, AssignedDate: "2024-01-16", IsActive: true },
  { CaravanClientID: 5, CaravanID: 2, ClientID: 16, AssignedDate: "2024-01-25", IsActive: true },
  { CaravanClientID: 6, CaravanID: 2, ClientID: 26, AssignedDate: "2024-02-05", IsActive: true },
  { CaravanClientID: 7, CaravanID: 3, ClientID: 3, AssignedDate: "2024-01-17", IsActive: true },
  { CaravanClientID: 8, CaravanID: 3, ClientID: 17, AssignedDate: "2024-01-30", IsActive: true },
  { CaravanClientID: 9, CaravanID: 3, ClientID: 27, AssignedDate: "2024-02-10", IsActive: true },
  { CaravanClientID: 10, CaravanID: 4, ClientID: 4, AssignedDate: "2024-01-18", IsActive: true },
  { CaravanClientID: 11, CaravanID: 4, ClientID: 18, AssignedDate: "2024-02-02", IsActive: true },
  { CaravanClientID: 12, CaravanID: 4, ClientID: 28, AssignedDate: "2024-02-15", IsActive: true },
  { CaravanClientID: 13, CaravanID: 5, ClientID: 5, AssignedDate: "2024-01-19", IsActive: true },
  { CaravanClientID: 14, CaravanID: 5, ClientID: 19, AssignedDate: "2024-02-03", IsActive: true },
  { CaravanClientID: 15, CaravanID: 5, ClientID: 29, AssignedDate: "2024-02-20", IsActive: true },
  { CaravanClientID: 16, CaravanID: 6, ClientID: 10, AssignedDate: "2024-01-20", IsActive: true },
  { CaravanClientID: 17, CaravanID: 6, ClientID: 20, AssignedDate: "2024-02-05", IsActive: true },
  { CaravanClientID: 18, CaravanID: 6, ClientID: 30, AssignedDate: "2024-02-25", IsActive: true },
  { CaravanClientID: 19, CaravanID: 7, ClientID: 11, AssignedDate: "2024-01-21", IsActive: true },
  { CaravanClientID: 20, CaravanID: 7, ClientID: 22, AssignedDate: "2024-02-08", IsActive: true },
  { CaravanClientID: 21, CaravanID: 7, ClientID: 31, AssignedDate: "2024-02-28", IsActive: true },
  { CaravanClientID: 22, CaravanID: 8, ClientID: 12, AssignedDate: "2024-01-22", IsActive: true },
  { CaravanClientID: 23, CaravanID: 8, ClientID: 23, AssignedDate: "2024-02-10", IsActive: true },
  { CaravanClientID: 24, CaravanID: 8, ClientID: 32, AssignedDate: "2024-03-01", IsActive: true },
  { CaravanClientID: 25, CaravanID: 9, ClientID: 13, AssignedDate: "2024-01-23", IsActive: true },
  { CaravanClientID: 26, CaravanID: 9, ClientID: 24, AssignedDate: "2024-02-12", IsActive: true },
  { CaravanClientID: 27, CaravanID: 9, ClientID: 33, AssignedDate: "2024-03-03", IsActive: true },
  { CaravanClientID: 28, CaravanID: 10, ClientID: 14, AssignedDate: "2024-01-24", IsActive: true },
  { CaravanClientID: 29, CaravanID: 10, ClientID: 25, AssignedDate: "2024-02-15", IsActive: true },
  { CaravanClientID: 30, CaravanID: 10, ClientID: 34, AssignedDate: "2024-03-05", IsActive: true },
  { CaravanClientID: 31, CaravanID: 11, ClientID: 35, AssignedDate: "2024-03-07", IsActive: true },

  // Continue assigning clients to remaining caravans
  { CaravanClientID: 32, CaravanID: 12, ClientID: 36, AssignedDate: "2024-01-25", IsActive: true },
  { CaravanClientID: 33, CaravanID: 12, ClientID: 37, AssignedDate: "2024-02-08", IsActive: true },
  { CaravanClientID: 34, CaravanID: 13, ClientID: 38, AssignedDate: "2024-01-26", IsActive: true },
  { CaravanClientID: 35, CaravanID: 13, ClientID: 39, AssignedDate: "2024-02-09", IsActive: true },
  { CaravanClientID: 36, CaravanID: 14, ClientID: 40, AssignedDate: "2024-01-27", IsActive: true },
  { CaravanClientID: 37, CaravanID: 14, ClientID: 41, AssignedDate: "2024-02-10", IsActive: true },
  { CaravanClientID: 38, CaravanID: 15, ClientID: 42, AssignedDate: "2024-01-28", IsActive: true },
  { CaravanClientID: 39, CaravanID: 15, ClientID: 43, AssignedDate: "2024-02-11", IsActive: true },
  { CaravanClientID: 40, CaravanID: 16, ClientID: 44, AssignedDate: "2024-01-29", IsActive: true },
  { CaravanClientID: 41, CaravanID: 16, ClientID: 45, AssignedDate: "2024-02-12", IsActive: true },
  { CaravanClientID: 42, CaravanID: 17, ClientID: 46, AssignedDate: "2024-01-30", IsActive: true },
  { CaravanClientID: 43, CaravanID: 17, ClientID: 47, AssignedDate: "2024-02-13", IsActive: true },
  { CaravanClientID: 44, CaravanID: 18, ClientID: 48, AssignedDate: "2024-01-31", IsActive: true },
  { CaravanClientID: 45, CaravanID: 18, ClientID: 49, AssignedDate: "2024-02-14", IsActive: true },
  { CaravanClientID: 46, CaravanID: 19, ClientID: 50, AssignedDate: "2024-02-01", IsActive: true },
  { CaravanClientID: 47, CaravanID: 19, ClientID: 51, AssignedDate: "2024-02-15", IsActive: true },
  { CaravanClientID: 48, CaravanID: 20, ClientID: 52, AssignedDate: "2024-02-02", IsActive: true },
  { CaravanClientID: 49, CaravanID: 20, ClientID: 53, AssignedDate: "2024-02-16", IsActive: true },
  { CaravanClientID: 50, CaravanID: 21, ClientID: 54, AssignedDate: "2024-02-03", IsActive: true },
  { CaravanClientID: 51, CaravanID: 21, ClientID: 55, AssignedDate: "2024-02-17", IsActive: true },
  { CaravanClientID: 52, CaravanID: 22, ClientID: 56, AssignedDate: "2024-02-04", IsActive: true },
  { CaravanClientID: 53, CaravanID: 22, ClientID: 57, AssignedDate: "2024-02-18", IsActive: true },
  { CaravanClientID: 54, CaravanID: 23, ClientID: 58, AssignedDate: "2024-02-05", IsActive: true },
  { CaravanClientID: 55, CaravanID: 23, ClientID: 59, AssignedDate: "2024-02-19", IsActive: true },
  { CaravanClientID: 56, CaravanID: 24, ClientID: 60, AssignedDate: "2024-02-06", IsActive: true },
  { CaravanClientID: 57, CaravanID: 24, ClientID: 61, AssignedDate: "2024-02-20", IsActive: true },
  { CaravanClientID: 58, CaravanID: 25, ClientID: 62, AssignedDate: "2024-02-07", IsActive: true },
  { CaravanClientID: 59, CaravanID: 25, ClientID: 63, AssignedDate: "2024-02-21", IsActive: true },
  { CaravanClientID: 60, CaravanID: 26, ClientID: 64, AssignedDate: "2024-02-08", IsActive: true },
  { CaravanClientID: 61, CaravanID: 26, ClientID: 65, AssignedDate: "2024-02-22", IsActive: true },
  { CaravanClientID: 62, CaravanID: 27, ClientID: 66, AssignedDate: "2024-02-09", IsActive: true },
  { CaravanClientID: 63, CaravanID: 27, ClientID: 67, AssignedDate: "2024-02-23", IsActive: true },
  { CaravanClientID: 64, CaravanID: 28, ClientID: 68, AssignedDate: "2024-02-10", IsActive: true },
  { CaravanClientID: 65, CaravanID: 28, ClientID: 69, AssignedDate: "2024-02-24", IsActive: true },
  { CaravanClientID: 66, CaravanID: 29, ClientID: 70, AssignedDate: "2024-02-11", IsActive: true },
  { CaravanClientID: 67, CaravanID: 29, ClientID: 71, AssignedDate: "2024-02-25", IsActive: true },
  { CaravanClientID: 68, CaravanID: 30, ClientID: 72, AssignedDate: "2024-02-12", IsActive: true },
  { CaravanClientID: 69, CaravanID: 30, ClientID: 73, AssignedDate: "2024-02-26", IsActive: true },
  { CaravanClientID: 70, CaravanID: 31, ClientID: 74, AssignedDate: "2024-02-13", IsActive: true },
  { CaravanClientID: 71, CaravanID: 31, ClientID: 75, AssignedDate: "2024-02-27", IsActive: true },
  { CaravanClientID: 72, CaravanID: 32, ClientID: 76, AssignedDate: "2024-02-14", IsActive: true },
  { CaravanClientID: 73, CaravanID: 32, ClientID: 77, AssignedDate: "2024-02-28", IsActive: true },
  { CaravanClientID: 74, CaravanID: 33, ClientID: 78, AssignedDate: "2024-02-15", IsActive: true },
  { CaravanClientID: 75, CaravanID: 33, ClientID: 79, AssignedDate: "2024-03-01", IsActive: true },
  { CaravanClientID: 76, CaravanID: 34, ClientID: 80, AssignedDate: "2024-02-16", IsActive: true },
  { CaravanClientID: 77, CaravanID: 34, ClientID: 81, AssignedDate: "2024-03-02", IsActive: true },
  { CaravanClientID: 78, CaravanID: 35, ClientID: 82, AssignedDate: "2024-02-17", IsActive: true },
  { CaravanClientID: 79, CaravanID: 35, ClientID: 83, AssignedDate: "2024-03-03", IsActive: true },
  { CaravanClientID: 80, CaravanID: 36, ClientID: 84, AssignedDate: "2024-02-18", IsActive: true },
  { CaravanClientID: 81, CaravanID: 36, ClientID: 85, AssignedDate: "2024-03-04", IsActive: true },
  { CaravanClientID: 82, CaravanID: 37, ClientID: 86, AssignedDate: "2024-02-19", IsActive: true },
  { CaravanClientID: 83, CaravanID: 37, ClientID: 87, AssignedDate: "2024-03-05", IsActive: true },
  { CaravanClientID: 84, CaravanID: 38, ClientID: 88, AssignedDate: "2024-02-20", IsActive: true },
  { CaravanClientID: 85, CaravanID: 38, ClientID: 89, AssignedDate: "2024-03-06", IsActive: true },
  { CaravanClientID: 86, CaravanID: 39, ClientID: 90, AssignedDate: "2024-02-21", IsActive: true },

  // Assign some clients to remaining caravans (40-45) for balanced distribution
  { CaravanClientID: 87, CaravanID: 40, ClientID: 1, AssignedDate: "2024-03-10", IsActive: false }, // Reassignment
  { CaravanClientID: 88, CaravanID: 41, ClientID: 5, AssignedDate: "2024-03-11", IsActive: false }, // Reassignment
  { CaravanClientID: 89, CaravanID: 42, ClientID: 10, AssignedDate: "2024-03-12", IsActive: false }, // Reassignment
  { CaravanClientID: 90, CaravanID: 43, ClientID: 15, AssignedDate: "2024-03-13", IsActive: false }, // Reassignment
  { CaravanClientID: 91, CaravanID: 44, ClientID: 20, AssignedDate: "2024-03-14", IsActive: false }, // Reassignment
  { CaravanClientID: 92, CaravanID: 45, ClientID: 25, AssignedDate: "2024-03-15", IsActive: false }  // Reassignment
];

// Mock CSV data parsed into objects
const clientsData: Client[] = [
  { ClientID: 1, FullName: "GARCIA, MARIA C.", ProductType: "AFP PENSION", MarketType: "VIRGIN", ClientType: "POTENTIAL", PensionType: "RETIREE-OPTIONAL", PAN: "2024000001", Age: 65, Birthday: "1959-03-12", Gmail: "maria.garcia@gmail.com", FacebookLink: "facebook.com/maria.garcia" },
  { ClientID: 2, FullName: "DELA CRUZ, JUAN P.", ProductType: "PNP INP", MarketType: "EXISTING", ClientType: "EXISTING", PensionType: "RETIREE-COMPULSORY", PAN: "2024000002", Age: 72, Birthday: "1952-07-05", Gmail: "juan.delacruz@gmail.com", FacebookLink: "facebook.com/juan.delacruz" },
  { ClientID: 3, FullName: "SANTOS, MARIA L.", ProductType: "BFP ACTIVE", MarketType: "VIRGIN", ClientType: "POTENTIAL", PensionType: "TPPD-SPOUSE", PAN: "2024000003", Age: 58, Birthday: "1966-11-22", Gmail: "maria.santos@gmail.com", FacebookLink: "facebook.com/maria.santos" },
  { ClientID: 4, FullName: "REYES, KRISTINE D.", ProductType: "AFP MINOR", MarketType: "FULLYPAID", ClientType: "EXISTING", PensionType: "POSTHUMOUS-MINOR", PAN: "2024000004", Age: 42, Birthday: "1982-02-18", Gmail: "kristine.reyes@gmail.com", FacebookLink: "facebook.com/kristine.reyes" },
  { ClientID: 5, FullName: "SANTIAGO, ROSMAR S.", ProductType: "NAPOLCOM", MarketType: "OTHERS", ClientType: "POTENTIAL", PensionType: "TRANSFEREE-SPOUSE", PAN: "2024000005", Age: 60, Birthday: "1964-01-30", Gmail: "rosmar.santiago@gmail.com", FacebookLink: "facebook.com/rosmar.santiago" },
  { ClientID: 10, FullName: "FERNANDEZ, ELENA S.", ProductType: "AFP PENSION", MarketType: "OTHERS", ClientType: "EXISTING", PensionType: "RETIREE-COMPULSORY", PAN: "2024000010", Age: 70, Birthday: "1954-06-09", Gmail: "elena.fernandez@gmail.com", FacebookLink: "facebook.com/elena.fernandez" },
  { ClientID: 11, FullName: "BONIFACIO, ANDRES M.", ProductType: "BFP PENSION", MarketType: "VIRGIN", ClientType: "POTENTIAL", PensionType: "RETIREE-OPTIONAL", PAN: "2024000011", Age: 67, Birthday: "1957-12-01", Gmail: "andres.bonifacio@gmail.com", FacebookLink: "facebook.com/andres.bonifacio" },
  { ClientID: 12, FullName: "RIZAL, JOSE P.", ProductType: "PNP INP", MarketType: "EXISTING", ClientType: "POTENTIAL", PensionType: "TPPD-RETIREE", PAN: "2024000012", Age: 75, Birthday: "1949-06-19", Gmail: "jose.rizal@gmail.com", FacebookLink: "facebook.com/jose.rizal" },
  { ClientID: 13, FullName: "AQUINO, CORAZON C.", ProductType: "AFP MINOR", MarketType: "VIRGIN", ClientType: "POTENTIAL", PensionType: "POSTHUMOUS-SPOUSE", PAN: "2024000013", Age: 52, Birthday: "1972-09-23", Gmail: "corazon.aquino@gmail.com", FacebookLink: "facebook.com/corazon.aquino" },
  { ClientID: 14, FullName: "MARCOS, FERDINAND E.", ProductType: "BFP STP", MarketType: "FULLYPAID", ClientType: "EXISTING", PensionType: "TRANSFEREE-MINOR", PAN: "2024000014", Age: 68, Birthday: "1956-12-30", Gmail: "ferdinand.marcos@gmail.com", FacebookLink: "facebook.com/ferdinand.marcos" },
  
  // Additional Potential Clients
  { ClientID: 15, FullName: "LOPEZ, CARMEN A.", ProductType: "AFP PENSION", MarketType: "VIRGIN", ClientType: "POTENTIAL", PensionType: "RETIREE-OPTIONAL", PAN: "2024000015", Age: 63, Birthday: "1961-08-14", Gmail: "carmen.lopez@gmail.com", FacebookLink: "facebook.com/carmen.lopez" },
  { ClientID: 16, FullName: "CRUZ, ROBERTO L.", ProductType: "BFP ACTIVE", MarketType: "VIRGIN", ClientType: "POTENTIAL", PensionType: "TPPD-SPOUSE", PAN: "2024000016", Age: 55, Birthday: "1969-04-22", Gmail: "roberto.cruz@gmail.com", FacebookLink: "facebook.com/roberto.cruz" },
  { ClientID: 17, FullName: "MORALES, JENNIFER B.", ProductType: "AFP MINOR", MarketType: "VIRGIN", ClientType: "POTENTIAL", PensionType: "POSTHUMOUS-MINOR", PAN: "2024000017", Age: 38, Birthday: "1986-11-03", Gmail: "jennifer.morales@gmail.com", FacebookLink: "facebook.com/jennifer.morales" },
  { ClientID: 18, FullName: "TORRES, MIGUEL R.", ProductType: "NAPOLCOM", MarketType: "OTHERS", ClientType: "POTENTIAL", PensionType: "TRANSFEREE-SPOUSE", PAN: "2024000018", Age: 59, Birthday: "1965-02-17", Gmail: "miguel.torres@gmail.com", FacebookLink: "facebook.com/miguel.torres" },
  { ClientID: 19, FullName: "RAMOS, LINDA G.", ProductType: "BFP PENSION", MarketType: "VIRGIN", ClientType: "POTENTIAL", PensionType: "RETIREE-COMPULSORY", PAN: "2024000019", Age: 69, Birthday: "1955-09-28", Gmail: "linda.ramos@gmail.com", FacebookLink: "facebook.com/linda.ramos" },
  { ClientID: 20, FullName: "VILLANUEVA, ANTONIO F.", ProductType: "PNP INP", MarketType: "EXISTING", ClientType: "POTENTIAL", PensionType: "TPPD-RETIREE", PAN: "2024000020", Age: 74, Birthday: "1950-12-11", Gmail: "antonio.villanueva@gmail.com", FacebookLink: "facebook.com/antonio.villanueva" },
  { ClientID: 21, FullName: "MENDOZA, ROSARIO D.", ProductType: "AFP PENSION", MarketType: "VIRGIN", ClientType: "POTENTIAL", PensionType: "RETIREE-OPTIONAL", PAN: "2024000021", Age: 64, Birthday: "1960-06-05", Gmail: "rosario.mendoza@gmail.com", FacebookLink: "facebook.com/rosario.mendoza" },
  { ClientID: 22, FullName: "CASTRO, BENJAMIN H.", ProductType: "BFP STP", MarketType: "FULLYPAID", ClientType: "POTENTIAL", PensionType: "TRANSFEREE-MINOR", PAN: "2024000022", Age: 45, Birthday: "1979-03-19", Gmail: "benjamin.castro@gmail.com", FacebookLink: "facebook.com/benjamin.castro" },
  { ClientID: 23, FullName: "FLORES, PATRICIA M.", ProductType: "AFP MINOR", MarketType: "VIRGIN", ClientType: "POTENTIAL", PensionType: "POSTHUMOUS-SPOUSE", PAN: "2024000023", Age: 48, Birthday: "1976-07-13", Gmail: "patricia.flores@gmail.com", FacebookLink: "facebook.com/patricia.flores" },
  { ClientID: 24, FullName: "HERRERA, RICARDO J.", ProductType: "NAPOLCOM", MarketType: "OTHERS", ClientType: "POTENTIAL", PensionType: "TRANSFEREE-SPOUSE", PAN: "2024000024", Age: 57, Birthday: "1967-10-26", Gmail: "ricardo.herrera@gmail.com", FacebookLink: "facebook.com/ricardo.herrera" },
  { ClientID: 25, FullName: "GUTIERREZ, ELIZABETH K.", ProductType: "BFP ACTIVE", MarketType: "VIRGIN", ClientType: "POTENTIAL", PensionType: "TPPD-SPOUSE", PAN: "2024000025", Age: 53, Birthday: "1971-01-08", Gmail: "elizabeth.gutierrez@gmail.com", FacebookLink: "facebook.com/elizabeth.gutierrez" },

  // Additional Existing Clients
  { ClientID: 26, FullName: "ALVAREZ, CARLOS N.", ProductType: "AFP PENSION", MarketType: "EXISTING", ClientType: "EXISTING", PensionType: "RETIREE-COMPULSORY", PAN: "2024000026", Age: 71, Birthday: "1953-05-15", Gmail: "carlos.alvarez@gmail.com", FacebookLink: "facebook.com/carlos.alvarez" },
  { ClientID: 27, FullName: "JIMENEZ, AURORA P.", ProductType: "BFP PENSION", MarketType: "FULLYPAID", ClientType: "EXISTING", PensionType: "RETIREE-OPTIONAL", PAN: "2024000027", Age: 68, Birthday: "1956-08-29", Gmail: "aurora.jimenez@gmail.com", FacebookLink: "facebook.com/aurora.jimenez" },
  { ClientID: 28, FullName: "ROMERO, FRANCISCO Q.", ProductType: "PNP INP", MarketType: "EXISTING", ClientType: "EXISTING", PensionType: "TPPD-RETIREE", PAN: "2024000028", Age: 76, Birthday: "1948-11-02", Gmail: "francisco.romero@gmail.com", FacebookLink: "facebook.com/francisco.romero" },
  { ClientID: 29, FullName: "DIAZ, VICTORIA R.", ProductType: "AFP MINOR", MarketType: "FULLYPAID", ClientType: "EXISTING", PensionType: "POSTHUMOUS-MINOR", PAN: "2024000029", Age: 41, Birthday: "1983-04-07", Gmail: "victoria.diaz@gmail.com", FacebookLink: "facebook.com/victoria.diaz" },
  { ClientID: 30, FullName: "VARGAS, MANUEL S.", ProductType: "BFP STP", MarketType: "OTHERS", ClientType: "EXISTING", PensionType: "TRANSFEREE-MINOR", PAN: "2024000030", Age: 47, Birthday: "1977-12-20", Gmail: "manuel.vargas@gmail.com", FacebookLink: "facebook.com/manuel.vargas" },
  { ClientID: 31, FullName: "ORTIZ, GLADYS T.", ProductType: "NAPOLCOM", MarketType: "EXISTING", ClientType: "EXISTING", PensionType: "TRANSFEREE-SPOUSE", PAN: "2024000031", Age: 61, Birthday: "1963-09-16", Gmail: "gladys.ortiz@gmail.com", FacebookLink: "facebook.com/gladys.ortiz" },
  { ClientID: 32, FullName: "RUIZ, EDUARDO U.", ProductType: "AFP PENSION", MarketType: "OTHERS", ClientType: "EXISTING", PensionType: "RETIREE-COMPULSORY", PAN: "2024000032", Age: 73, Birthday: "1951-02-28", Gmail: "eduardo.ruiz@gmail.com", FacebookLink: "facebook.com/eduardo.ruiz" },
  { ClientID: 33, FullName: "PEÑA, DOLORES V.", ProductType: "BFP ACTIVE", MarketType: "EXISTING", ClientType: "EXISTING", PensionType: "TPPD-SPOUSE", PAN: "2024000033", Age: 56, Birthday: "1968-06-12", Gmail: "dolores.pena@gmail.com", FacebookLink: "facebook.com/dolores.pena" },
  { ClientID: 34, FullName: "AGUILAR, ARTURO W.", ProductType: "AFP MINOR", MarketType: "FULLYPAID", ClientType: "EXISTING", PensionType: "POSTHUMOUS-SPOUSE", PAN: "2024000034", Age: 49, Birthday: "1975-10-24", Gmail: "arturo.aguilar@gmail.com", FacebookLink: "facebook.com/arturo.aguilar" },
  { ClientID: 35, FullName: "MEDINA, ESPERANZA X.", ProductType: "BFP PENSION", MarketType: "OTHERS", ClientType: "EXISTING", PensionType: "RETIREE-OPTIONAL", PAN: "2024000035", Age: 66, Birthday: "1958-03-06", Gmail: "esperanza.medina@gmail.com", FacebookLink: "facebook.com/esperanza.medina" },

  // Additional clients for more caravans
  { ClientID: 36, FullName: "BAUTISTA, RICARDO L.", ProductType: "AFP PENSION", MarketType: "VIRGIN", ClientType: "POTENTIAL", PensionType: "RETIREE-OPTIONAL", PAN: "2024000036", Age: 62, Birthday: "1962-04-15", Gmail: "ricardo.bautista@gmail.com", FacebookLink: "facebook.com/ricardo.bautista" },
  { ClientID: 37, FullName: "NAVARRO, LOURDES M.", ProductType: "BFP ACTIVE", MarketType: "EXISTING", ClientType: "POTENTIAL", PensionType: "TPPD-SPOUSE", PAN: "2024000037", Age: 54, Birthday: "1970-07-28", Gmail: "lourdes.navarro@gmail.com", FacebookLink: "facebook.com/lourdes.navarro" },
  { ClientID: 38, FullName: "SALAZAR, BENJAMIN Q.", ProductType: "PNP INP", MarketType: "OTHERS", ClientType: "EXISTING", PensionType: "RETIREE-COMPULSORY", PAN: "2024000038", Age: 73, Birthday: "1951-11-12", Gmail: "benjamin.salazar@gmail.com", FacebookLink: "facebook.com/benjamin.salazar" },
  { ClientID: 39, FullName: "VALENCIA, THERESA R.", ProductType: "AFP MINOR", MarketType: "FULLYPAID", ClientType: "POTENTIAL", PensionType: "POSTHUMOUS-MINOR", PAN: "2024000039", Age: 43, Birthday: "1981-08-07", Gmail: "theresa.valencia@gmail.com", FacebookLink: "facebook.com/theresa.valencia" },
  { ClientID: 40, FullName: "PADILLA, ERNESTO S.", ProductType: "NAPOLCOM", MarketType: "VIRGIN", ClientType: "POTENTIAL", PensionType: "TRANSFEREE-SPOUSE", PAN: "2024000040", Age: 58, Birthday: "1966-03-22", Gmail: "ernesto.padilla@gmail.com", FacebookLink: "facebook.com/ernesto.padilla" },
  { ClientID: 41, FullName: "DELA ROSA, CRISTINA T.", ProductType: "BFP PENSION", MarketType: "EXISTING", ClientType: "EXISTING", PensionType: "RETIREE-OPTIONAL", PAN: "2024000041", Age: 67, Birthday: "1957-12-18", Gmail: "cristina.delarosa@gmail.com", FacebookLink: "facebook.com/cristina.delarosa" },
  { ClientID: 42, FullName: "ESPINOSA, RAMON U.", ProductType: "AFP PENSION", MarketType: "OTHERS", ClientType: "POTENTIAL", PensionType: "TPPD-RETIREE", PAN: "2024000042", Age: 71, Birthday: "1953-09-03", Gmail: "ramon.espinosa@gmail.com", FacebookLink: "facebook.com/ramon.espinosa" },
  { ClientID: 43, FullName: "GONZALES, MARIA CLARA V.", ProductType: "BFP STP", MarketType: "VIRGIN", ClientType: "POTENTIAL", PensionType: "TRANSFEREE-MINOR", PAN: "2024000043", Age: 46, Birthday: "1978-05-14", Gmail: "mariaclara.gonzales@gmail.com", FacebookLink: "facebook.com/mariaclara.gonzales" },
  { ClientID: 44, FullName: "MANUEL, ARTURO W.", ProductType: "AFP MINOR", MarketType: "FULLYPAID", ClientType: "EXISTING", PensionType: "POSTHUMOUS-SPOUSE", PAN: "2024000044", Age: 50, Birthday: "1974-01-29", Gmail: "arturo.manuel@gmail.com", FacebookLink: "facebook.com/arturo.manuel" },
  { ClientID: 45, FullName: "CORTEZ, FELICIA X.", ProductType: "PNP INP", MarketType: "EXISTING", ClientType: "POTENTIAL", PensionType: "RETIREE-COMPULSORY", PAN: "2024000045", Age: 69, Birthday: "1955-10-11", Gmail: "felicia.cortez@gmail.com", FacebookLink: "facebook.com/felicia.cortez" },
  { ClientID: 46, FullName: "RIVERA, DOMINGO Y.", ProductType: "NAPOLCOM", MarketType: "OTHERS", ClientType: "EXISTING", PensionType: "TRANSFEREE-SPOUSE", PAN: "2024000046", Age: 61, Birthday: "1963-06-25", Gmail: "domingo.rivera@gmail.com", FacebookLink: "facebook.com/domingo.rivera" },
  { ClientID: 47, FullName: "SANTOS, GLORIA Z.", ProductType: "BFP ACTIVE", MarketType: "VIRGIN", ClientType: "POTENTIAL", PensionType: "TPPD-SPOUSE", PAN: "2024000047", Age: 55, Birthday: "1969-02-08", Gmail: "gloria.santos@gmail.com", FacebookLink: "facebook.com/gloria.santos" },
  { ClientID: 48, FullName: "MAGNO, TEODORO A.", ProductType: "AFP PENSION", MarketType: "FULLYPAID", ClientType: "EXISTING", PensionType: "RETIREE-OPTIONAL", PAN: "2024000048", Age: 65, Birthday: "1959-04-17", Gmail: "teodoro.magno@gmail.com", FacebookLink: "facebook.com/teodoro.magno" },
  { ClientID: 49, FullName: "CRUZ, REMEDIOS B.", ProductType: "BFP PENSION", MarketType: "VIRGIN", ClientType: "POTENTIAL", PensionType: "RETIREE-COMPULSORY", PAN: "2024000049", Age: 68, Birthday: "1956-12-04", Gmail: "remedios.cruz@gmail.com", FacebookLink: "facebook.com/remedios.cruz" },
  { ClientID: 50, FullName: "MORENO, LEONARDO C.", ProductType: "AFP MINOR", MarketType: "EXISTING", ClientType: "POTENTIAL", PensionType: "POSTHUMOUS-MINOR", PAN: "2024000050", Age: 44, Birthday: "1980-11-23", Gmail: "leonardo.moreno@gmail.com", FacebookLink: "facebook.com/leonardo.moreno" },
  { ClientID: 51, FullName: "TRINIDAD, SOCORRO D.", ProductType: "BFP STP", MarketType: "OTHERS", ClientType: "EXISTING", PensionType: "TRANSFEREE-MINOR", PAN: "2024000051", Age: 48, Birthday: "1976-07-16", Gmail: "socorro.trinidad@gmail.com", FacebookLink: "facebook.com/socorro.trinidad" },
  { ClientID: 52, FullName: "PASCUAL, ALFREDO E.", ProductType: "NAPOLCOM", MarketType: "VIRGIN", ClientType: "POTENTIAL", PensionType: "TRANSFEREE-SPOUSE", PAN: "2024000052", Age: 59, Birthday: "1965-03-09", Gmail: "alfredo.pascual@gmail.com", FacebookLink: "facebook.com/alfredo.pascual" },
  { ClientID: 53, FullName: "AQUINO, MILAGROS F.", ProductType: "AFP PENSION", MarketType: "FULLYPAID", ClientType: "EXISTING", PensionType: "RETIREE-COMPULSORY", PAN: "2024000053", Age: 72, Birthday: "1952-08-20", Gmail: "milagros.aquino@gmail.com", FacebookLink: "facebook.com/milagros.aquino" },
  { ClientID: 54, FullName: "DELGADO, RODOLFO G.", ProductType: "PNP INP", MarketType: "EXISTING", ClientType: "POTENTIAL", PensionType: "TPPD-RETIREE", PAN: "2024000054", Age: 74, Birthday: "1950-05-31", Gmail: "rodolfo.delgado@gmail.com", FacebookLink: "facebook.com/rodolfo.delgado" },
  { ClientID: 55, FullName: "VEGA, CONSOLACION H.", ProductType: "BFP ACTIVE", MarketType: "VIRGIN", ClientType: "POTENTIAL", PensionType: "TPPD-SPOUSE", PAN: "2024000055", Age: 56, Birthday: "1968-01-13", Gmail: "consolacion.vega@gmail.com", FacebookLink: "facebook.com/consolacion.vega" },
  { ClientID: 56, FullName: "OCAMPO, FERNANDO I.", ProductType: "AFP MINOR", MarketType: "OTHERS", ClientType: "EXISTING", PensionType: "POSTHUMOUS-SPOUSE", PAN: "2024000056", Age: 51, Birthday: "1973-09-26", Gmail: "fernando.ocampo@gmail.com", FacebookLink: "facebook.com/fernando.ocampo" },
  { ClientID: 57, FullName: "RAMOS, ESTRELLA J.", ProductType: "BFP PENSION", MarketType: "FULLYPAID", ClientType: "POTENTIAL", PensionType: "RETIREE-OPTIONAL", PAN: "2024000057", Age: 64, Birthday: "1960-06-18", Gmail: "estrella.ramos@gmail.com", FacebookLink: "facebook.com/estrella.ramos" },
  { ClientID: 58, FullName: "CAPISTRANO, SALVADOR K.", ProductType: "NAPOLCOM", MarketType: "EXISTING", ClientType: "EXISTING", PensionType: "TRANSFEREE-SPOUSE", PAN: "2024000058", Age: 60, Birthday: "1964-04-02", Gmail: "salvador.capistrano@gmail.com", FacebookLink: "facebook.com/salvador.capistrano" },
  { ClientID: 59, FullName: "LOZANO, PACITA L.", ProductType: "AFP PENSION", MarketType: "VIRGIN", ClientType: "POTENTIAL", PensionType: "RETIREE-COMPULSORY", PAN: "2024000059", Age: 70, Birthday: "1954-11-27", Gmail: "pacita.lozano@gmail.com", FacebookLink: "facebook.com/pacita.lozano" },
  { ClientID: 60, FullName: "HERRERA, RODRIGO M.", ProductType: "BFP STP", MarketType: "OTHERS", ClientType: "POTENTIAL", PensionType: "TRANSFEREE-MINOR", PAN: "2024000060", Age: 47, Birthday: "1977-08-14", Gmail: "rodrigo.herrera@gmail.com", FacebookLink: "facebook.com/rodrigo.herrera" },

  // Additional clients to distribute among remaining caravans
  { ClientID: 61, FullName: "VILLANUEVA, CONSUELO N.", ProductType: "PNP INP", MarketType: "VIRGIN", ClientType: "POTENTIAL", PensionType: "TPPD-RETIREE", PAN: "2024000061", Age: 75, Birthday: "1949-12-01", Gmail: "consuelo.villanueva@gmail.com", FacebookLink: "facebook.com/consuelo.villanueva" },
  { ClientID: 62, FullName: "GUERRERO, NESTOR O.", ProductType: "AFP MINOR", MarketType: "EXISTING", ClientType: "EXISTING", PensionType: "POSTHUMOUS-MINOR", PAN: "2024000062", Age: 42, Birthday: "1982-03-17", Gmail: "nestor.guerrero@gmail.com", FacebookLink: "facebook.com/nestor.guerrero" },
  { ClientID: 63, FullName: "MENDEZ, CORAZON P.", ProductType: "BFP ACTIVE", MarketType: "FULLYPAID", ClientType: "POTENTIAL", PensionType: "TPPD-SPOUSE", PAN: "2024000063", Age: 53, Birthday: "1971-07-09", Gmail: "corazon.mendez@gmail.com", FacebookLink: "facebook.com/corazon.mendez" },
  { ClientID: 64, FullName: "SANTILLAN, ALEJANDRO Q.", ProductType: "NAPOLCOM", MarketType: "OTHERS", ClientType: "EXISTING", PensionType: "TRANSFEREE-SPOUSE", PAN: "2024000064", Age: 57, Birthday: "1967-10-22", Gmail: "alejandro.santillan@gmail.com", FacebookLink: "facebook.com/alejandro.santillan" },
  { ClientID: 65, FullName: "MOLINA, ROSALINDA R.", ProductType: "AFP PENSION", MarketType: "VIRGIN", ClientType: "POTENTIAL", PensionType: "RETIREE-OPTIONAL", PAN: "2024000065", Age: 63, Birthday: "1961-05-05", Gmail: "rosalinda.molina@gmail.com", FacebookLink: "facebook.com/rosalinda.molina" },

  // Continue adding clients for the remaining caravans (66-90)
  { ClientID: 66, FullName: "DOMINGO, OSCAR S.", ProductType: "BFP PENSION", MarketType: "EXISTING", ClientType: "POTENTIAL", PensionType: "RETIREE-COMPULSORY", PAN: "2024000066", Age: 69, Birthday: "1955-01-18", Gmail: "oscar.domingo@gmail.com", FacebookLink: "facebook.com/oscar.domingo" },
  { ClientID: 67, FullName: "GALVEZ, PURIFICACION T.", ProductType: "PNP INP", MarketType: "FULLYPAID", ClientType: "EXISTING", PensionType: "TPPD-RETIREE", PAN: "2024000067", Age: 76, Birthday: "1948-09-11", Gmail: "purificacion.galvez@gmail.com", FacebookLink: "facebook.com/purificacion.galvez" },
  { ClientID: 68, FullName: "MARQUEZ, EDUARDO U.", ProductType: "AFP MINOR", MarketType: "VIRGIN", ClientType: "POTENTIAL", PensionType: "POSTHUMOUS-SPOUSE", PAN: "2024000068", Age: 49, Birthday: "1975-02-24", Gmail: "eduardo.marquez@gmail.com", FacebookLink: "facebook.com/eduardo.marquez" },
  { ClientID: 69, FullName: "VALENZUELA, TRINIDAD V.", ProductType: "BFP STP", MarketType: "OTHERS", ClientType: "EXISTING", PensionType: "TRANSFEREE-MINOR", PAN: "2024000069", Age: 45, Birthday: "1979-06-16", Gmail: "trinidad.valenzuela@gmail.com", FacebookLink: "facebook.com/trinidad.valenzuela" },
  { ClientID: 70, FullName: "SORIANO, MANUEL W.", ProductType: "NAPOLCOM", MarketType: "EXISTING", ClientType: "POTENTIAL", PensionType: "TRANSFEREE-SPOUSE", PAN: "2024000070", Age: 58, Birthday: "1966-04-29", Gmail: "manuel.soriano@gmail.com", FacebookLink: "facebook.com/manuel.soriano" },

  { ClientID: 71, FullName: "CABRERA, VISITACION X.", ProductType: "AFP PENSION", MarketType: "VIRGIN", ClientType: "POTENTIAL", PensionType: "RETIREE-OPTIONAL", PAN: "2024000071", Age: 62, Birthday: "1962-11-07", Gmail: "visitacion.cabrera@gmail.com", FacebookLink: "facebook.com/visitacion.cabrera" },
  { ClientID: 72, FullName: "GUTIERREZ, PANTALEON Y.", ProductType: "BFP ACTIVE", MarketType: "FULLYPAID", ClientType: "EXISTING", PensionType: "TPPD-SPOUSE", PAN: "2024000072", Age: 54, Birthday: "1970-08-13", Gmail: "pantaleon.gutierrez@gmail.com", FacebookLink: "facebook.com/pantaleon.gutierrez" },
  { ClientID: 73, FullName: "MERCADO, SOLEDAD Z.", ProductType: "PNP INP", MarketType: "OTHERS", ClientType: "POTENTIAL", PensionType: "RETIREE-COMPULSORY", PAN: "2024000073", Age: 71, Birthday: "1953-03-30", Gmail: "soledad.mercado@gmail.com", FacebookLink: "facebook.com/soledad.mercado" },
  { ClientID: 74, FullName: "AUSTRIA, RODRIGO A.", ProductType: "AFP MINOR", MarketType: "EXISTING", ClientType: "EXISTING", PensionType: "POSTHUMOUS-MINOR", PAN: "2024000074", Age: 41, Birthday: "1983-12-21", Gmail: "rodrigo.austria@gmail.com", FacebookLink: "facebook.com/rodrigo.austria" },
  { ClientID: 75, FullName: "SEVILLA, FELICIDAD B.", ProductType: "BFP PENSION", MarketType: "VIRGIN", ClientType: "POTENTIAL", PensionType: "RETIREE-OPTIONAL", PAN: "2024000075", Age: 66, Birthday: "1958-07-04", Gmail: "felicidad.sevilla@gmail.com", FacebookLink: "facebook.com/felicidad.sevilla" },

  { ClientID: 76, FullName: "ALONZO, GREGORIO C.", ProductType: "NAPOLCOM", MarketType: "FULLYPAID", ClientType: "EXISTING", PensionType: "TRANSFEREE-SPOUSE", PAN: "2024000076", Age: 59, Birthday: "1965-01-26", Gmail: "gregorio.alonzo@gmail.com", FacebookLink: "facebook.com/gregorio.alonzo" },
  { ClientID: 77, FullName: "CORDERO, ESPERANZA D.", ProductType: "AFP PENSION", MarketType: "OTHERS", ClientType: "POTENTIAL", PensionType: "TPPD-RETIREE", PAN: "2024000077", Age: 73, Birthday: "1951-10-19", Gmail: "esperanza.cordero@gmail.com", FacebookLink: "facebook.com/esperanza.cordero" },
  { ClientID: 78, FullName: "FERNANDO, LEOPOLDO E.", ProductType: "BFP STP", MarketType: "EXISTING", ClientType: "EXISTING", PensionType: "TRANSFEREE-MINOR", PAN: "2024000078", Age: 46, Birthday: "1978-04-12", Gmail: "leopoldo.fernando@gmail.com", FacebookLink: "facebook.com/leopoldo.fernando" },
  { ClientID: 79, FullName: "SANTIAGO, NORMA F.", ProductType: "PNP INP", MarketType: "VIRGIN", ClientType: "POTENTIAL", PensionType: "RETIREE-COMPULSORY", PAN: "2024000079", Age: 68, Birthday: "1956-08-05", Gmail: "norma.santiago@gmail.com", FacebookLink: "facebook.com/norma.santiago" },
  { ClientID: 80, FullName: "LEGASPI, HERMINIO G.", ProductType: "AFP MINOR", MarketType: "FULLYPAID", ClientType: "POTENTIAL", PensionType: "POSTHUMOUS-SPOUSE", PAN: "2024000080", Age: 52, Birthday: "1972-11-28", Gmail: "herminio.legaspi@gmail.com", FacebookLink: "facebook.com/herminio.legaspi" },

  { ClientID: 81, FullName: "BERMUDEZ, CATALINA H.", ProductType: "BFP ACTIVE", MarketType: "OTHERS", ClientType: "EXISTING", PensionType: "TPPD-SPOUSE", PAN: "2024000081", Age: 55, Birthday: "1969-06-10", Gmail: "catalina.bermudez@gmail.com", FacebookLink: "facebook.com/catalina.bermudez" },
  { ClientID: 82, FullName: "TOLENTINO, ESTEBAN I.", ProductType: "NAPOLCOM", MarketType: "EXISTING", ClientType: "POTENTIAL", PensionType: "TRANSFEREE-SPOUSE", PAN: "2024000082", Age: 60, Birthday: "1964-02-17", Gmail: "esteban.tolentino@gmail.com", FacebookLink: "facebook.com/esteban.tolentino" },
  { ClientID: 83, FullName: "MENDOZA, TERESITA J.", ProductType: "AFP PENSION", MarketType: "VIRGIN", ClientType: "POTENTIAL", PensionType: "RETIREE-OPTIONAL", PAN: "2024000083", Age: 64, Birthday: "1960-09-03", Gmail: "teresita.mendoza@gmail.com", FacebookLink: "facebook.com/teresita.mendoza" },
  { ClientID: 84, FullName: "AGUSTIN, MARCELO K.", ProductType: "BFP PENSION", MarketType: "FULLYPAID", ClientType: "EXISTING", PensionType: "RETIREE-COMPULSORY", PAN: "2024000084", Age: 67, Birthday: "1957-05-14", Gmail: "marcelo.agustin@gmail.com", FacebookLink: "facebook.com/marcelo.agustin" },
  { ClientID: 85, FullName: "VILLENA, REMEDIOS L.", ProductType: "PNP INP", MarketType: "OTHERS", ClientType: "POTENTIAL", PensionType: "TPPD-RETIREE", PAN: "2024000085", Age: 74, Birthday: "1950-12-23", Gmail: "remedios.villena@gmail.com", FacebookLink: "facebook.com/remedios.villena" },

  { ClientID: 86, FullName: "PASCUA, FLORENCIO M.", ProductType: "AFP MINOR", MarketType: "EXISTING", ClientType: "EXISTING", PensionType: "POSTHUMOUS-MINOR", PAN: "2024000086", Age: 43, Birthday: "1981-01-15", Gmail: "florencio.pascua@gmail.com", FacebookLink: "facebook.com/florencio.pascua" },
  { ClientID: 87, FullName: "LORENZO, IMELDA N.", ProductType: "BFP STP", MarketType: "VIRGIN", ClientType: "POTENTIAL", PensionType: "TRANSFEREE-MINOR", PAN: "2024000087", Age: 47, Birthday: "1977-07-08", Gmail: "imelda.lorenzo@gmail.com", FacebookLink: "facebook.com/imelda.lorenzo" },
  { ClientID: 88, FullName: "VELASCO, ISIDRO O.", ProductType: "NAPOLCOM", MarketType: "FULLYPAID", ClientType: "EXISTING", PensionType: "TRANSFEREE-SPOUSE", PAN: "2024000088", Age: 61, Birthday: "1963-03-21", Gmail: "isidro.velasco@gmail.com", FacebookLink: "facebook.com/isidro.velasco" },
  { ClientID: 89, FullName: "BARTOLOME, ROSARIO P.", ProductType: "AFP PENSION", MarketType: "OTHERS", ClientType: "POTENTIAL", PensionType: "RETIREE-COMPULSORY", PAN: "2024000089", Age: 70, Birthday: "1954-08-12", Gmail: "rosario.bartolome@gmail.com", FacebookLink: "facebook.com/rosario.bartolome" },
  { ClientID: 90, FullName: "TAMAYO, GUILLERMO Q.", ProductType: "BFP ACTIVE", MarketType: "EXISTING", ClientType: "POTENTIAL", PensionType: "TPPD-SPOUSE", PAN: "2024000090", Age: 56, Birthday: "1968-04-25", Gmail: "guillermo.tamayo@gmail.com", FacebookLink: "facebook.com/guillermo.tamayo" }
];

const addressesData: Address[] = [
  { AddressID: 1, ClientID: 1, Street: "Purok 5, Brgy. San Roque", Municipality: "Quezon City", Province: "Metro Manila", IsDefault: true },
  { AddressID: 2, ClientID: 2, Street: "Blk 12 Lot 3, Brgy. Sto. Niño", Municipality: "Caloocan", Province: "Metro Manila", IsDefault: true },
  { AddressID: 3, ClientID: 3, Street: "Zone 2, Brgy. Mabini", Municipality: "Legazpi City", Province: "Albay", IsDefault: true },
  { AddressID: 4, ClientID: 4, Street: "Purok 4, Brgy. Poblacion", Municipality: "San Fernando", Province: "Pampanga", IsDefault: true },
  { AddressID: 5, ClientID: 5, Street: "Brgy. Talisay", Municipality: "Nasugbu", Province: "Batangas", IsDefault: true },
  { AddressID: 6, ClientID: 5, Street: "Purok 6, Brgy. Wawa", Municipality: "Taguig", Province: "Metro Manila", IsDefault: false },
  { AddressID: 7, ClientID: 10, Street: "Brgy. Bagumbayan", Municipality: "Taguig", Province: "Metro Manila", IsDefault: true },
  { AddressID: 8, ClientID: 11, Street: "Zone 5, Brgy. Lapasan", Municipality: "Cagayan de Oro", Province: "Misamis Oriental", IsDefault: true },
  { AddressID: 9, ClientID: 12, Street: "Purok 8, Brgy. Pag-asa", Municipality: "San Jose", Province: "Nueva Ecija", IsDefault: true },
  { AddressID: 10, ClientID: 13, Street: "Brgy. San Miguel", Municipality: "Iloilo City", Province: "Iloilo", IsDefault: true },
  { AddressID: 11, ClientID: 14, Street: "Zone 3, Brgy. Maharlika", Municipality: "Baguio City", Province: "Benguet", IsDefault: true },
  
  // Additional addresses for new clients
  { AddressID: 12, ClientID: 15, Street: "Blk 7 Lot 15, Brgy. Santo Domingo", Municipality: "Quezon City", Province: "Metro Manila", IsDefault: true },
  { AddressID: 13, ClientID: 16, Street: "Purok 2, Brgy. Santolan", Municipality: "Pasig City", Province: "Metro Manila", IsDefault: true },
  { AddressID: 14, ClientID: 17, Street: "Zone 4, Brgy. Maligaya", Municipality: "Antipolo", Province: "Rizal", IsDefault: true },
  { AddressID: 15, ClientID: 18, Street: "Brgy. San Antonio", Municipality: "Makati City", Province: "Metro Manila", IsDefault: true },
  { AddressID: 16, ClientID: 19, Street: "Purok 3, Brgy. Libis", Municipality: "Quezon City", Province: "Metro Manila", IsDefault: true },
  { AddressID: 17, ClientID: 20, Street: "Zone 1, Brgy. Poblacion", Municipality: "Marikina City", Province: "Metro Manila", IsDefault: true },
  { AddressID: 18, ClientID: 21, Street: "Blk 22 Lot 8, Brgy. Bagong Silang", Municipality: "Caloocan", Province: "Metro Manila", IsDefault: true },
  { AddressID: 19, ClientID: 22, Street: "Purok 7, Brgy. Banaba", Municipality: "San Mateo", Province: "Rizal", IsDefault: true },
  { AddressID: 20, ClientID: 23, Street: "Zone 6, Brgy. Rosario", Municipality: "Pasig City", Province: "Metro Manila", IsDefault: true },
  { AddressID: 21, ClientID: 24, Street: "Brgy. San Rafael", Municipality: "Montalban", Province: "Rizal", IsDefault: true },
  { AddressID: 22, ClientID: 25, Street: "Purok 9, Brgy. Mayamot", Municipality: "Antipolo", Province: "Rizal", IsDefault: true },
  { AddressID: 23, ClientID: 26, Street: "Blk 33 Lot 12, Brgy. Payatas", Municipality: "Quezon City", Province: "Metro Manila", IsDefault: true },
  { AddressID: 24, ClientID: 27, Street: "Zone 8, Brgy. Kapitolyo", Municipality: "Pasig City", Province: "Metro Manila", IsDefault: true },
  { AddressID: 25, ClientID: 28, Street: "Purok 1, Brgy. Manggahan", Municipality: "Pasig City", Province: "Metro Manila", IsDefault: true },
  { AddressID: 26, ClientID: 29, Street: "Brgy. Ugong Norte", Municipality: "Quezon City", Province: "Metro Manila", IsDefault: true },
  { AddressID: 27, ClientID: 30, Street: "Zone 9, Brgy. Addition Hills", Municipality: "Mandaluyong", Province: "Metro Manila", IsDefault: true },
  { AddressID: 28, ClientID: 31, Street: "Purok 4, Brgy. Pinagbuhatan", Municipality: "Pasig City", Province: "Metro Manila", IsDefault: true },
  { AddressID: 29, ClientID: 32, Street: "Blk 18 Lot 25, Brgy. Tumana", Municipality: "Marikina City", Province: "Metro Manila", IsDefault: true },
  { AddressID: 30, ClientID: 33, Street: "Zone 2, Brgy. Concepcion", Municipality: "Marikina City", Province: "Metro Manila", IsDefault: true },
  { AddressID: 31, ClientID: 34, Street: "Purok 8, Brgy. Parang", Municipality: "Marikina City", Province: "Metro Manila", IsDefault: true },
  { AddressID: 32, ClientID: 35, Street: "Brgy. Jesus dela Peña", Municipality: "Marikina City", Province: "Metro Manila", IsDefault: true },

  // Additional addresses for new clients (36-90)
  { AddressID: 33, ClientID: 36, Street: "Purok 5, Brgy. San Vicente", Municipality: "Quezon City", Province: "Metro Manila", IsDefault: true },
  { AddressID: 34, ClientID: 37, Street: "Zone 3, Brgy. Poblacion", Municipality: "Pasig City", Province: "Metro Manila", IsDefault: true },
  { AddressID: 35, ClientID: 38, Street: "Blk 15 Lot 9, Brgy. Bagong Pag-asa", Municipality: "Quezon City", Province: "Metro Manila", IsDefault: true },
  { AddressID: 36, ClientID: 39, Street: "Purok 7, Brgy. San Isidro", Municipality: "Antipolo", Province: "Rizal", IsDefault: true },
  { AddressID: 37, ClientID: 40, Street: "Zone 5, Brgy. Bagumbayan", Municipality: "Taguig", Province: "Metro Manila", IsDefault: true },
  { AddressID: 38, ClientID: 41, Street: "Brgy. Sta. Ana", Municipality: "Marikina City", Province: "Metro Manila", IsDefault: true },
  { AddressID: 39, ClientID: 42, Street: "Purok 2, Brgy. San Miguel", Municipality: "San Mateo", Province: "Rizal", IsDefault: true },
  { AddressID: 40, ClientID: 43, Street: "Zone 8, Brgy. Poblacion", Municipality: "Montalban", Province: "Rizal", IsDefault: true },
  { AddressID: 41, ClientID: 44, Street: "Blk 9 Lot 17, Brgy. Mayamot", Municipality: "Antipolo", Province: "Rizal", IsDefault: true },
  { AddressID: 42, ClientID: 45, Street: "Purok 4, Brgy. Libis", Municipality: "Quezon City", Province: "Metro Manila", IsDefault: true },
  { AddressID: 43, ClientID: 46, Street: "Zone 1, Brgy. Rosario", Municipality: "Pasig City", Province: "Metro Manila", IsDefault: true },
  { AddressID: 44, ClientID: 47, Street: "Brgy. San Pedro", Municipality: "Makati City", Province: "Metro Manila", IsDefault: true },
  { AddressID: 45, ClientID: 48, Street: "Purok 6, Brgy. Addition Hills", Municipality: "Mandaluyong", Province: "Metro Manila", IsDefault: true },
  { AddressID: 46, ClientID: 49, Street: "Zone 4, Brgy. Concepcion", Municipality: "Marikina City", Province: "Metro Manila", IsDefault: true },
  { AddressID: 47, ClientID: 50, Street: "Blk 11 Lot 23, Brgy. Tumana", Municipality: "Marikina City", Province: "Metro Manila", IsDefault: true },
  { AddressID: 48, ClientID: 51, Street: "Purok 8, Brgy. Parang", Municipality: "Marikina City", Province: "Metro Manila", IsDefault: true },
  { AddressID: 49, ClientID: 52, Street: "Zone 6, Brgy. Kapitolyo", Municipality: "Pasig City", Province: "Metro Manila", IsDefault: true },
  { AddressID: 50, ClientID: 53, Street: "Brgy. Pinagbuhatan", Municipality: "Pasig City", Province: "Metro Manila", IsDefault: true },
  { AddressID: 51, ClientID: 54, Street: "Purok 3, Brgy. Manggahan", Municipality: "Pasig City", Province: "Metro Manila", IsDefault: true },
  { AddressID: 52, ClientID: 55, Street: "Zone 9, Brgy. Ugong Norte", Municipality: "Quezon City", Province: "Metro Manila", IsDefault: true },
  { AddressID: 53, ClientID: 56, Street: "Blk 20 Lot 14, Brgy. Payatas", Municipality: "Quezon City", Province: "Metro Manila", IsDefault: true },
  { AddressID: 54, ClientID: 57, Street: "Purok 1, Brgy. Bagong Silang", Municipality: "Caloocan", Province: "Metro Manila", IsDefault: true },
  { AddressID: 55, ClientID: 58, Street: "Zone 2, Brgy. Banaba", Municipality: "San Mateo", Province: "Rizal", IsDefault: true },
  { AddressID: 56, ClientID: 59, Street: "Brgy. San Rafael", Municipality: "Montalban", Province: "Rizal", IsDefault: true },
  { AddressID: 57, ClientID: 60, Street: "Purok 5, Brgy. Santo Domingo", Municipality: "Quezon City", Province: "Metro Manila", IsDefault: true },
  { AddressID: 58, ClientID: 61, Street: "Zone 7, Brgy. Santolan", Municipality: "Pasig City", Province: "Metro Manila", IsDefault: true },
  { AddressID: 59, ClientID: 62, Street: "Blk 25 Lot 18, Brgy. Maligaya", Municipality: "Antipolo", Province: "Rizal", IsDefault: true },
  { AddressID: 60, ClientID: 63, Street: "Purok 9, Brgy. San Antonio", Municipality: "Makati City", Province: "Metro Manila", IsDefault: true },
  { AddressID: 61, ClientID: 64, Street: "Zone 4, Brgy. Libis", Municipality: "Quezon City", Province: "Metro Manila", IsDefault: true },
  { AddressID: 62, ClientID: 65, Street: "Brgy. Poblacion", Municipality: "Marikina City", Province: "Metro Manila", IsDefault: true },
  { AddressID: 63, ClientID: 66, Street: "Purok 2, Brgy. Bagong Pag-asa", Municipality: "Quezon City", Province: "Metro Manila", IsDefault: true },
  { AddressID: 64, ClientID: 67, Street: "Zone 8, Brgy. Kapitolyo", Municipality: "Pasig City", Province: "Metro Manila", IsDefault: true },
  { AddressID: 65, ClientID: 68, Street: "Blk 12 Lot 30, Brgy. Manggahan", Municipality: "Pasig City", Province: "Metro Manila", IsDefault: true },
  { AddressID: 66, ClientID: 69, Street: "Purok 6, Brgy. Ugong Norte", Municipality: "Quezon City", Province: "Metro Manila", IsDefault: true },
  { AddressID: 67, ClientID: 70, Street: "Zone 1, Brgy. Addition Hills", Municipality: "Mandaluyong", Province: "Metro Manila", IsDefault: true },
  { AddressID: 68, ClientID: 71, Street: "Brgy. Pinagbuhatan", Municipality: "Pasig City", Province: "Metro Manila", IsDefault: true },
  { AddressID: 69, ClientID: 72, Street: "Purok 4, Brgy. Tumana", Municipality: "Marikina City", Province: "Metro Manila", IsDefault: true },
  { AddressID: 70, ClientID: 73, Street: "Zone 3, Brgy. Concepcion", Municipality: "Marikina City", Province: "Metro Manila", IsDefault: true },
  { AddressID: 71, ClientID: 74, Street: "Blk 8 Lot 21, Brgy. Parang", Municipality: "Marikina City", Province: "Metro Manila", IsDefault: true },
  { AddressID: 72, ClientID: 75, Street: "Purok 7, Brgy. Jesus dela Peña", Municipality: "Marikina City", Province: "Metro Manila", IsDefault: true },
  { AddressID: 73, ClientID: 76, Street: "Zone 5, Brgy. San Vicente", Municipality: "Quezon City", Province: "Metro Manila", IsDefault: true },
  { AddressID: 74, ClientID: 77, Street: "Brgy. Poblacion", Municipality: "Pasig City", Province: "Metro Manila", IsDefault: true },
  { AddressID: 75, ClientID: 78, Street: "Purok 3, Brgy. Bagong Pag-asa", Municipality: "Quezon City", Province: "Metro Manila", IsDefault: true },
  { AddressID: 76, ClientID: 79, Street: "Zone 6, Brgy. San Isidro", Municipality: "Antipolo", Province: "Rizal", IsDefault: true },
  { AddressID: 77, ClientID: 80, Street: "Blk 19 Lot 16, Brgy. Bagumbayan", Municipality: "Taguig", Province: "Metro Manila", IsDefault: true },
  { AddressID: 78, ClientID: 81, Street: "Purok 1, Brgy. Sta. Ana", Municipality: "Marikina City", Province: "Metro Manila", IsDefault: true },
  { AddressID: 79, ClientID: 82, Street: "Zone 9, Brgy. San Miguel", Municipality: "San Mateo", Province: "Rizal", IsDefault: true },
  { AddressID: 80, ClientID: 83, Street: "Brgy. Poblacion", Municipality: "Montalban", Province: "Rizal", IsDefault: true },
  { AddressID: 81, ClientID: 84, Street: "Purok 5, Brgy. Mayamot", Municipality: "Antipolo", Province: "Rizal", IsDefault: true },
  { AddressID: 82, ClientID: 85, Street: "Zone 2, Brgy. Libis", Municipality: "Quezon City", Province: "Metro Manila", IsDefault: true },
  { AddressID: 83, ClientID: 86, Street: "Blk 16 Lot 27, Brgy. Rosario", Municipality: "Pasig City", Province: "Metro Manila", IsDefault: true },
  { AddressID: 84, ClientID: 87, Street: "Purok 8, Brgy. San Pedro", Municipality: "Makati City", Province: "Metro Manila", IsDefault: true },
  { AddressID: 85, ClientID: 88, Street: "Zone 4, Brgy. Addition Hills", Municipality: "Mandaluyong", Province: "Metro Manila", IsDefault: true },
  { AddressID: 86, ClientID: 89, Street: "Brgy. Concepcion", Municipality: "Marikina City", Province: "Metro Manila", IsDefault: true },
  { AddressID: 87, ClientID: 90, Street: "Purok 7, Brgy. Tumana", Municipality: "Marikina City", Province: "Metro Manila", IsDefault: true }
];

const phoneNumbersData: PhoneNumber[] = [
  { PhoneID: 1, ClientID: 1, PhoneNumber: "09171234567", IsPrimary: true },
  { PhoneID: 2, ClientID: 2, PhoneNumber: "09981234567", IsPrimary: true },
  { PhoneID: 3, ClientID: 3, PhoneNumber: "09181230045", IsPrimary: true },
  { PhoneID: 4, ClientID: 4, PhoneNumber: "09201239876", IsPrimary: true },
  { PhoneID: 5, ClientID: 5, PhoneNumber: "09170005678", IsPrimary: true },
  { PhoneID: 6, ClientID: 5, PhoneNumber: "09381239876", IsPrimary: false },
  { PhoneID: 7, ClientID: 10, PhoneNumber: "09195554433", IsPrimary: true },
  { PhoneID: 8, ClientID: 11, PhoneNumber: "09223334455", IsPrimary: true },
  { PhoneID: 9, ClientID: 12, PhoneNumber: "09180001122", IsPrimary: true },
  { PhoneID: 10, ClientID: 13, PhoneNumber: "09998887766", IsPrimary: true },
  { PhoneID: 11, ClientID: 14, PhoneNumber: "09285556677", IsPrimary: true },
  
  // Additional phone numbers for new clients
  { PhoneID: 12, ClientID: 15, PhoneNumber: "09125551234", IsPrimary: true },
  { PhoneID: 13, ClientID: 16, PhoneNumber: "09365552345", IsPrimary: true },
  { PhoneID: 14, ClientID: 17, PhoneNumber: "09175553456", IsPrimary: true },
  { PhoneID: 15, ClientID: 18, PhoneNumber: "09185554567", IsPrimary: true },
  { PhoneID: 16, ClientID: 19, PhoneNumber: "09195555678", IsPrimary: true },
  { PhoneID: 17, ClientID: 20, PhoneNumber: "09205556789", IsPrimary: true },
  { PhoneID: 18, ClientID: 21, PhoneNumber: "09215557890", IsPrimary: true },
  { PhoneID: 19, ClientID: 22, PhoneNumber: "09225558901", IsPrimary: true },
  { PhoneID: 20, ClientID: 23, PhoneNumber: "09235559012", IsPrimary: true },
  { PhoneID: 21, ClientID: 24, PhoneNumber: "09245550123", IsPrimary: true },
  { PhoneID: 22, ClientID: 25, PhoneNumber: "09255551234", IsPrimary: true },
  { PhoneID: 23, ClientID: 26, PhoneNumber: "09265552345", IsPrimary: true },
  { PhoneID: 24, ClientID: 27, PhoneNumber: "09275553456", IsPrimary: true },
  { PhoneID: 25, ClientID: 28, PhoneNumber: "09285554567", IsPrimary: true },
  { PhoneID: 26, ClientID: 29, PhoneNumber: "09295555678", IsPrimary: true },
  { PhoneID: 27, ClientID: 30, PhoneNumber: "09305556789", IsPrimary: true },
  { PhoneID: 28, ClientID: 31, PhoneNumber: "09315557890", IsPrimary: true },
  { PhoneID: 29, ClientID: 32, PhoneNumber: "09325558901", IsPrimary: true },
  { PhoneID: 30, ClientID: 33, PhoneNumber: "09335559012", IsPrimary: true },
  { PhoneID: 31, ClientID: 34, PhoneNumber: "09345550123", IsPrimary: true },
  { PhoneID: 32, ClientID: 35, PhoneNumber: "09355551234", IsPrimary: true },
  
  // Some clients with secondary phone numbers
  { PhoneID: 33, ClientID: 15, PhoneNumber: "09991112233", IsPrimary: false },
  { PhoneID: 34, ClientID: 18, PhoneNumber: "09992223344", IsPrimary: false },
  { PhoneID: 35, ClientID: 22, PhoneNumber: "09993334455", IsPrimary: false },
  { PhoneID: 36, ClientID: 26, PhoneNumber: "09994445566", IsPrimary: false },
  { PhoneID: 37, ClientID: 30, PhoneNumber: "09995556677", IsPrimary: false },

  // Phone numbers for clients 36-90
  { PhoneID: 38, ClientID: 36, PhoneNumber: "09365556789", IsPrimary: true },
  { PhoneID: 39, ClientID: 37, PhoneNumber: "09375557890", IsPrimary: true },
  { PhoneID: 40, ClientID: 38, PhoneNumber: "09385558901", IsPrimary: true },
  { PhoneID: 41, ClientID: 39, PhoneNumber: "09395559012", IsPrimary: true },
  { PhoneID: 42, ClientID: 40, PhoneNumber: "09405550123", IsPrimary: true },
  { PhoneID: 43, ClientID: 41, PhoneNumber: "09415551234", IsPrimary: true },
  { PhoneID: 44, ClientID: 42, PhoneNumber: "09425552345", IsPrimary: true },
  { PhoneID: 45, ClientID: 43, PhoneNumber: "09435553456", IsPrimary: true },
  { PhoneID: 46, ClientID: 44, PhoneNumber: "09445554567", IsPrimary: true },
  { PhoneID: 47, ClientID: 45, PhoneNumber: "09455555678", IsPrimary: true },
  { PhoneID: 48, ClientID: 46, PhoneNumber: "09465556789", IsPrimary: true },
  { PhoneID: 49, ClientID: 47, PhoneNumber: "09475557890", IsPrimary: true },
  { PhoneID: 50, ClientID: 48, PhoneNumber: "09485558901", IsPrimary: true },
  { PhoneID: 51, ClientID: 49, PhoneNumber: "09495559012", IsPrimary: true },
  { PhoneID: 52, ClientID: 50, PhoneNumber: "09505550123", IsPrimary: true },
  { PhoneID: 53, ClientID: 51, PhoneNumber: "09515551234", IsPrimary: true },
  { PhoneID: 54, ClientID: 52, PhoneNumber: "09525552345", IsPrimary: true },
  { PhoneID: 55, ClientID: 53, PhoneNumber: "09535553456", IsPrimary: true },
  { PhoneID: 56, ClientID: 54, PhoneNumber: "09545554567", IsPrimary: true },
  { PhoneID: 57, ClientID: 55, PhoneNumber: "09555555678", IsPrimary: true },
  { PhoneID: 58, ClientID: 56, PhoneNumber: "09565556789", IsPrimary: true },
  { PhoneID: 59, ClientID: 57, PhoneNumber: "09575557890", IsPrimary: true },
  { PhoneID: 60, ClientID: 58, PhoneNumber: "09585558901", IsPrimary: true },
  { PhoneID: 61, ClientID: 59, PhoneNumber: "09595559012", IsPrimary: true },
  { PhoneID: 62, ClientID: 60, PhoneNumber: "09605550123", IsPrimary: true },
  { PhoneID: 63, ClientID: 61, PhoneNumber: "09615551234", IsPrimary: true },
  { PhoneID: 64, ClientID: 62, PhoneNumber: "09625552345", IsPrimary: true },
  { PhoneID: 65, ClientID: 63, PhoneNumber: "09635553456", IsPrimary: true },
  { PhoneID: 66, ClientID: 64, PhoneNumber: "09645554567", IsPrimary: true },
  { PhoneID: 67, ClientID: 65, PhoneNumber: "09655555678", IsPrimary: true },
  { PhoneID: 68, ClientID: 66, PhoneNumber: "09665556789", IsPrimary: true },
  { PhoneID: 69, ClientID: 67, PhoneNumber: "09675557890", IsPrimary: true },
  { PhoneID: 70, ClientID: 68, PhoneNumber: "09685558901", IsPrimary: true },
  { PhoneID: 71, ClientID: 69, PhoneNumber: "09695559012", IsPrimary: true },
  { PhoneID: 72, ClientID: 70, PhoneNumber: "09705550123", IsPrimary: true },
  { PhoneID: 73, ClientID: 71, PhoneNumber: "09715551234", IsPrimary: true },
  { PhoneID: 74, ClientID: 72, PhoneNumber: "09725552345", IsPrimary: true },
  { PhoneID: 75, ClientID: 73, PhoneNumber: "09735553456", IsPrimary: true },
  { PhoneID: 76, ClientID: 74, PhoneNumber: "09745554567", IsPrimary: true },
  { PhoneID: 77, ClientID: 75, PhoneNumber: "09755555678", IsPrimary: true },
  { PhoneID: 78, ClientID: 76, PhoneNumber: "09765556789", IsPrimary: true },
  { PhoneID: 79, ClientID: 77, PhoneNumber: "09775557890", IsPrimary: true },
  { PhoneID: 80, ClientID: 78, PhoneNumber: "09785558901", IsPrimary: true },
  { PhoneID: 81, ClientID: 79, PhoneNumber: "09795559012", IsPrimary: true },
  { PhoneID: 82, ClientID: 80, PhoneNumber: "09805550123", IsPrimary: true },
  { PhoneID: 83, ClientID: 81, PhoneNumber: "09815551234", IsPrimary: true },
  { PhoneID: 84, ClientID: 82, PhoneNumber: "09825552345", IsPrimary: true },
  { PhoneID: 85, ClientID: 83, PhoneNumber: "09835553456", IsPrimary: true },
  { PhoneID: 86, ClientID: 84, PhoneNumber: "09845554567", IsPrimary: true },
  { PhoneID: 87, ClientID: 85, PhoneNumber: "09855555678", IsPrimary: true },
  { PhoneID: 88, ClientID: 86, PhoneNumber: "09865556789", IsPrimary: true },
  { PhoneID: 89, ClientID: 87, PhoneNumber: "09875557890", IsPrimary: true },
  { PhoneID: 90, ClientID: 88, PhoneNumber: "09885558901", IsPrimary: true },
  { PhoneID: 91, ClientID: 89, PhoneNumber: "09895559012", IsPrimary: true },
  { PhoneID: 92, ClientID: 90, PhoneNumber: "09905550123", IsPrimary: true }
];

const visitsData: Visit[] = [
  { VisitID: 1, ClientID: 1, DateOfVisit: "2025-03-01", Address: "Quezon City, Metro Manila", Touchpoint: 1, TouchpointType: "Visit", ClientType: "POTENTIAL", Reason: "INTERESTED", TimeArrival: "09:30", OdometerArrival: "12345", TimeDeparture: "10:15", OdometerDeparture: "12348", NextVisitDate: "2025-03-10", Remarks: "Client interested, will prepare documents" },
  { VisitID: 2, ClientID: 1, DateOfVisit: "2025-03-10", Address: "Quezon City, Metro Manila", Touchpoint: 2, TouchpointType: "Call", ClientType: "POTENTIAL", Reason: "INTERESTED", TimeArrival: "14:00", OdometerArrival: "", TimeDeparture: "14:10", OdometerDeparture: "", NextVisitDate: "2025-03-15", Remarks: "Client confirmed interest after verification" },
  { VisitID: 3, ClientID: 1, DateOfVisit: "2025-03-15", Address: "Quezon City, Metro Manila", Touchpoint: 3, TouchpointType: "Call", ClientType: "POTENTIAL", Reason: "NOT AROUND", TimeArrival: "16:00", OdometerArrival: "", TimeDeparture: "16:05", OdometerDeparture: "", NextVisitDate: "2025-03-20", Remarks: "No answer, retry later" },
  { VisitID: 4, ClientID: 2, DateOfVisit: "2025-02-20", Address: "Caloocan, Metro Manila", Touchpoint: 6, TouchpointType: "Call", ClientType: "EXISTING", Reason: "FOR UPDATE", TimeArrival: "15:30", OdometerArrival: "", TimeDeparture: "15:50", OdometerDeparture: "", NextVisitDate: "2025-02-28", Remarks: "Updated pension details" },
  { VisitID: 5, ClientID: 3, DateOfVisit: "2025-01-12", Address: "Legazpi City, Albay", Touchpoint: 4, TouchpointType: "Visit", ClientType: "POTENTIAL", Reason: "LOAN INQUIRY", TimeArrival: "10:00", OdometerArrival: "87654", TimeDeparture: "10:35", OdometerDeparture: "87658", NextVisitDate: "2025-01-20", Remarks: "Asked about rates" },
  { VisitID: 6, ClientID: 4, DateOfVisit: "2025-02-05", Address: "San Fernando, Pampanga", Touchpoint: 7, TouchpointType: "Visit", ClientType: "EXISTING", Reason: "INTERESTED", TimeArrival: "13:00", OdometerArrival: "34500", TimeDeparture: "13:45", OdometerDeparture: "34505", NextVisitDate: "", Remarks: "Signed loan forms" },
  { VisitID: 7, ClientID: 5, DateOfVisit: "2025-01-18", Address: "Nasugbu, Batangas", Touchpoint: 2, TouchpointType: "Call", ClientType: "POTENTIAL", Reason: "NOT INTERESTED", TimeArrival: "09:00", OdometerArrival: "", TimeDeparture: "09:05", OdometerDeparture: "", NextVisitDate: "", Remarks: "Not interested at this time" },
  { VisitID: 8, ClientID: 10, DateOfVisit: "2025-03-02", Address: "Taguig, Metro Manila", Touchpoint: 5, TouchpointType: "Call", ClientType: "EXISTING", Reason: "FOR ADA COMPLIANCE", TimeArrival: "11:00", OdometerArrival: "", TimeDeparture: "11:20", OdometerDeparture: "", NextVisitDate: "2025-03-08", Remarks: "Needs ADA forms" },
  { VisitID: 9, ClientID: 11, DateOfVisit: "2025-03-04", Address: "Cagayan de Oro, Misamis Oriental", Touchpoint: 3, TouchpointType: "Call", ClientType: "POTENTIAL", Reason: "UNDECIDED", TimeArrival: "15:00", OdometerArrival: "", TimeDeparture: "15:15", OdometerDeparture: "", NextVisitDate: "2025-03-12", Remarks: "Still thinking about it" },
  { VisitID: 10, ClientID: 12, DateOfVisit: "2025-02-15", Address: "San Jose, Nueva Ecija", Touchpoint: 8, TouchpointType: "Call", ClientType: "POTENTIAL", Reason: "INTERESTED", TimeArrival: "16:30", OdometerArrival: "", TimeDeparture: "16:45", OdometerDeparture: "", NextVisitDate: "2025-02-25", Remarks: "Follow-up call scheduled" },
  { VisitID: 11, ClientID: 13, DateOfVisit: "2025-02-28", Address: "Iloilo City, Iloilo", Touchpoint: 1, TouchpointType: "Visit", ClientType: "POTENTIAL", Reason: "INTERESTED", TimeArrival: "08:45", OdometerArrival: "45600", TimeDeparture: "09:30", OdometerDeparture: "45605", NextVisitDate: "2025-03-05", Remarks: "Showed interest in AFP Minor benefits" },
  { VisitID: 12, ClientID: 13, DateOfVisit: "2025-03-05", Address: "Iloilo City, Iloilo", Touchpoint: 2, TouchpointType: "Call", ClientType: "POTENTIAL", Reason: "FOR VERIFICATION", TimeArrival: "14:30", OdometerArrival: "", TimeDeparture: "14:45", OdometerDeparture: "", NextVisitDate: "2025-03-12", Remarks: "Verified spouse details" },
  { VisitID: 13, ClientID: 14, DateOfVisit: "2025-01-25", Address: "Baguio City, Benguet", Touchpoint: 4, TouchpointType: "Visit", ClientType: "EXISTING", Reason: "FOR UPDATE", TimeArrival: "10:30", OdometerArrival: "67800", TimeDeparture: "11:15", OdometerDeparture: "67805", NextVisitDate: "2025-02-01", Remarks: "Updated transferee status" },
  { VisitID: 14, ClientID: 14, DateOfVisit: "2025-02-01", Address: "Baguio City, Benguet", Touchpoint: 5, TouchpointType: "Call", ClientType: "EXISTING", Reason: "INTERESTED", TimeArrival: "15:45", OdometerArrival: "", TimeDeparture: "16:00", OdometerDeparture: "", NextVisitDate: "2025-02-08", Remarks: "Interested in additional benefits" },
  
  // Additional visits for new clients
  { VisitID: 15, ClientID: 15, DateOfVisit: "2025-03-01", Address: "Quezon City, Metro Manila", Touchpoint: 1, TouchpointType: "Visit", ClientType: "POTENTIAL", Reason: "INTERESTED", TimeArrival: "10:00", OdometerArrival: "23400", TimeDeparture: "10:45", OdometerDeparture: "23405", NextVisitDate: "2025-03-08", Remarks: "Interested in AFP pension benefits" },
  { VisitID: 16, ClientID: 15, DateOfVisit: "2025-03-08", Address: "Quezon City, Metro Manila", Touchpoint: 2, TouchpointType: "Call", ClientType: "POTENTIAL", Reason: "INTERESTED", TimeArrival: "14:30", OdometerArrival: "", TimeDeparture: "14:45", OdometerDeparture: "", NextVisitDate: "2025-03-15", Remarks: "Confirmed interest, will prepare requirements" },
  { VisitID: 17, ClientID: 16, DateOfVisit: "2025-02-25", Address: "Pasig City, Metro Manila", Touchpoint: 1, TouchpointType: "Visit", ClientType: "POTENTIAL", Reason: "UNDECIDED", TimeArrival: "09:15", OdometerArrival: "45600", TimeDeparture: "10:00", OdometerDeparture: "45605", NextVisitDate: "2025-03-05", Remarks: "Needs time to think about benefits" },
  { VisitID: 18, ClientID: 16, DateOfVisit: "2025-03-05", Address: "Pasig City, Metro Manila", Touchpoint: 2, TouchpointType: "Call", ClientType: "POTENTIAL", Reason: "INTERESTED", TimeArrival: "15:00", OdometerArrival: "", TimeDeparture: "15:20", OdometerDeparture: "", NextVisitDate: "2025-03-12", Remarks: "Decided to proceed with application" },
  { VisitID: 19, ClientID: 17, DateOfVisit: "2025-03-03", Address: "Antipolo, Rizal", Touchpoint: 1, TouchpointType: "Visit", ClientType: "POTENTIAL", Reason: "INTERESTED", TimeArrival: "11:30", OdometerArrival: "67800", TimeDeparture: "12:15", OdometerDeparture: "67805", NextVisitDate: "2025-03-10", Remarks: "Interested in minor benefits coverage" },
  { VisitID: 20, ClientID: 18, DateOfVisit: "2025-02-28", Address: "Makati City, Metro Manila", Touchpoint: 1, TouchpointType: "Visit", ClientType: "POTENTIAL", Reason: "NOT INTERESTED", TimeArrival: "13:45", OdometerArrival: "89100", TimeDeparture: "14:00", OdometerDeparture: "89105", NextVisitDate: "", Remarks: "Not interested in current offerings" },
  { VisitID: 21, ClientID: 19, DateOfVisit: "2025-03-06", Address: "Quezon City, Metro Manila", Touchpoint: 1, TouchpointType: "Visit", ClientType: "POTENTIAL", Reason: "INTERESTED", TimeArrival: "08:30", OdometerArrival: "12300", TimeDeparture: "09:15", OdometerDeparture: "12305", NextVisitDate: "2025-03-13", Remarks: "Very interested in pension benefits" },
  { VisitID: 22, ClientID: 19, DateOfVisit: "2025-03-13", Address: "Quezon City, Metro Manila", Touchpoint: 2, TouchpointType: "Call", ClientType: "POTENTIAL", Reason: "FOR VERIFICATION", TimeArrival: "16:15", OdometerArrival: "", TimeDeparture: "16:30", OdometerDeparture: "", NextVisitDate: "2025-03-20", Remarks: "Verifying employment records" },
  { VisitID: 23, ClientID: 20, DateOfVisit: "2025-02-20", Address: "Marikina City, Metro Manila", Touchpoint: 1, TouchpointType: "Visit", ClientType: "POTENTIAL", Reason: "UNDECIDED", TimeArrival: "10:45", OdometerArrival: "56700", TimeDeparture: "11:30", OdometerDeparture: "56705", NextVisitDate: "2025-03-01", Remarks: "Comparing with other options" },
  { VisitID: 24, ClientID: 21, DateOfVisit: "2025-03-07", Address: "Caloocan, Metro Manila", Touchpoint: 1, TouchpointType: "Visit", ClientType: "POTENTIAL", Reason: "INTERESTED", TimeArrival: "14:00", OdometerArrival: "78900", TimeDeparture: "14:45", OdometerDeparture: "78905", NextVisitDate: "2025-03-14", Remarks: "Ready to start application process" },
  { VisitID: 25, ClientID: 22, DateOfVisit: "2025-02-18", Address: "San Mateo, Rizal", Touchpoint: 1, TouchpointType: "Visit", ClientType: "POTENTIAL", Reason: "NOT AROUND", TimeArrival: "09:00", OdometerArrival: "34500", TimeDeparture: "09:05", OdometerDeparture: "34500", NextVisitDate: "2025-02-25", Remarks: "No one home, left card" },
  { VisitID: 26, ClientID: 22, DateOfVisit: "2025-02-25", Address: "San Mateo, Rizal", Touchpoint: 2, TouchpointType: "Call", ClientType: "POTENTIAL", Reason: "INTERESTED", TimeArrival: "15:30", OdometerArrival: "", TimeDeparture: "15:50", OdometerDeparture: "", NextVisitDate: "2025-03-05", Remarks: "Interested after phone explanation" },
  { VisitID: 27, ClientID: 23, DateOfVisit: "2025-03-02", Address: "Pasig City, Metro Manila", Touchpoint: 1, TouchpointType: "Visit", ClientType: "POTENTIAL", Reason: "LOAN INQUIRY", TimeArrival: "11:15", OdometerArrival: "45600", TimeDeparture: "12:00", OdometerDeparture: "45605", NextVisitDate: "2025-03-09", Remarks: "Asked about loan interest rates" },
  { VisitID: 28, ClientID: 24, DateOfVisit: "2025-02-22", Address: "Montalban, Rizal", Touchpoint: 1, TouchpointType: "Visit", ClientType: "POTENTIAL", Reason: "UNDECIDED", TimeArrival: "13:30", OdometerArrival: "67800", TimeDeparture: "14:15", OdometerDeparture: "67805", NextVisitDate: "2025-03-02", Remarks: "Needs spousal consent" },
  { VisitID: 29, ClientID: 25, DateOfVisit: "2025-03-04", Address: "Antipolo, Rizal", Touchpoint: 1, TouchpointType: "Visit", ClientType: "POTENTIAL", Reason: "INTERESTED", TimeArrival: "09:45", OdometerArrival: "89100", TimeDeparture: "10:30", OdometerDeparture: "89105", NextVisitDate: "2025-03-11", Remarks: "Very positive response to presentation" },
  { VisitID: 30, ClientID: 25, DateOfVisit: "2025-03-11", Address: "Antipolo, Rizal", Touchpoint: 2, TouchpointType: "Call", ClientType: "POTENTIAL", Reason: "INTERESTED", TimeArrival: "14:45", OdometerArrival: "", TimeDeparture: "15:00", OdometerDeparture: "", NextVisitDate: "2025-03-18", Remarks: "Confirmed interest, scheduling document review" },
  
  // Visits for existing clients
  { VisitID: 31, ClientID: 26, DateOfVisit: "2025-02-15", Address: "Quezon City, Metro Manila", Touchpoint: 1, TouchpointType: "Visit", ClientType: "EXISTING", Reason: "FOR UPDATE", TimeArrival: "10:30", OdometerArrival: "12300", TimeDeparture: "11:15", OdometerDeparture: "12305", NextVisitDate: "2025-02-22", Remarks: "Updating beneficiary information" },
  { VisitID: 32, ClientID: 26, DateOfVisit: "2025-02-22", Address: "Quezon City, Metro Manila", Touchpoint: 2, TouchpointType: "Call", ClientType: "EXISTING", Reason: "FOR UPDATE", TimeArrival: "15:00", OdometerArrival: "", TimeDeparture: "15:15", OdometerDeparture: "", NextVisitDate: "2025-03-01", Remarks: "Completed beneficiary update" },
  { VisitID: 33, ClientID: 27, DateOfVisit: "2025-03-01", Address: "Pasig City, Metro Manila", Touchpoint: 1, TouchpointType: "Visit", ClientType: "EXISTING", Reason: "INTERESTED", TimeArrival: "11:00", OdometerArrival: "45600", TimeDeparture: "11:45", OdometerDeparture: "45605", NextVisitDate: "2025-03-08", Remarks: "Interested in additional coverage" },
  { VisitID: 34, ClientID: 28, DateOfVisit: "2025-02-28", Address: "Pasig City, Metro Manila", Touchpoint: 1, TouchpointType: "Visit", ClientType: "EXISTING", Reason: "FOR ADA COMPLIANCE", TimeArrival: "13:15", OdometerArrival: "67800", TimeDeparture: "14:00", OdometerDeparture: "67805", NextVisitDate: "2025-03-07", Remarks: "Reviewing ADA compliance requirements" },
  { VisitID: 35, ClientID: 29, DateOfVisit: "2025-03-05", Address: "Quezon City, Metro Manila", Touchpoint: 1, TouchpointType: "Visit", ClientType: "EXISTING", Reason: "FOR VERIFICATION", TimeArrival: "09:30", OdometerArrival: "89100", TimeDeparture: "10:15", OdometerDeparture: "89105", NextVisitDate: "2025-03-12", Remarks: "Verifying minor's school enrollment" },
  { VisitID: 36, ClientID: 30, DateOfVisit: "2025-02-18", Address: "Mandaluyong, Metro Manila", Touchpoint: 1, TouchpointType: "Visit", ClientType: "EXISTING", Reason: "INTERESTED", TimeArrival: "14:30", OdometerArrival: "12300", TimeDeparture: "15:15", OdometerDeparture: "12305", NextVisitDate: "2025-02-25", Remarks: "Interested in loan facility" },
  { VisitID: 37, ClientID: 31, DateOfVisit: "2025-03-03", Address: "Pasig City, Metro Manila", Touchpoint: 1, TouchpointType: "Visit", ClientType: "EXISTING", Reason: "FOR UPDATE", TimeArrival: "12:00", OdometerArrival: "45600", TimeDeparture: "12:45", OdometerDeparture: "45605", NextVisitDate: "2025-03-10", Remarks: "Updating contact information" },
  { VisitID: 38, ClientID: 32, DateOfVisit: "2025-02-25", Address: "Marikina City, Metro Manila", Touchpoint: 1, TouchpointType: "Visit", ClientType: "EXISTING", Reason: "FOR ADA COMPLIANCE", TimeArrival: "08:45", OdometerArrival: "67800", TimeDeparture: "09:30", OdometerDeparture: "67805", NextVisitDate: "2025-03-04", Remarks: "ADA compliance documentation review" },
  { VisitID: 39, ClientID: 33, DateOfVisit: "2025-03-06", Address: "Marikina City, Metro Manila", Touchpoint: 1, TouchpointType: "Visit", ClientType: "EXISTING", Reason: "INTERESTED", TimeArrival: "11:30", OdometerArrival: "89100", TimeDeparture: "12:15", OdometerDeparture: "89105", NextVisitDate: "2025-03-13", Remarks: "Interested in upgrading coverage" },
  { VisitID: 40, ClientID: 34, DateOfVisit: "2025-02-20", Address: "Marikina City, Metro Manila", Touchpoint: 1, TouchpointType: "Visit", ClientType: "EXISTING", Reason: "FOR VERIFICATION", TimeArrival: "15:45", OdometerArrival: "12300", TimeDeparture: "16:30", OdometerDeparture: "12305", NextVisitDate: "2025-02-27", Remarks: "Verifying spouse eligibility" },
  { VisitID: 41, ClientID: 35, DateOfVisit: "2025-03-08", Address: "Marikina City, Metro Manila", Touchpoint: 1, TouchpointType: "Visit", ClientType: "EXISTING", Reason: "FOR UPDATE", TimeArrival: "10:15", OdometerArrival: "45600", TimeDeparture: "11:00", OdometerDeparture: "45605", NextVisitDate: "2025-03-15", Remarks: "Annual update of pension details" },
  
  // Future scheduled visits for itinerary
  { VisitID: 42, ClientID: 1, DateOfVisit: "2025-03-15", Address: "Quezon City, Metro Manila", Touchpoint: 4, TouchpointType: "Visit", ClientType: "POTENTIAL", Reason: "INTERESTED", TimeArrival: "", OdometerArrival: "", TimeDeparture: "", OdometerDeparture: "", NextVisitDate: "2025-09-09", Remarks: "Scheduled follow-up visit" },
  { VisitID: 43, ClientID: 3, DateOfVisit: "2025-01-20", Address: "Legazpi City, Albay", Touchpoint: 5, TouchpointType: "Call", ClientType: "POTENTIAL", Reason: "LOAN INQUIRY", TimeArrival: "", OdometerArrival: "", TimeDeparture: "", OdometerDeparture: "", NextVisitDate: "2025-09-09", Remarks: "Follow-up on loan rates inquiry" },
  { VisitID: 44, ClientID: 10, DateOfVisit: "2025-03-08", Address: "Taguig, Metro Manila", Touchpoint: 6, TouchpointType: "Visit", ClientType: "EXISTING", Reason: "FOR ADA COMPLIANCE", TimeArrival: "", OdometerArrival: "", TimeDeparture: "", OdometerDeparture: "", NextVisitDate: "2025-09-10", Remarks: "Complete ADA forms submission" },
  { VisitID: 45, ClientID: 11, DateOfVisit: "2025-03-12", Address: "Cagayan de Oro, Misamis Oriental", Touchpoint: 4, TouchpointType: "Call", ClientType: "POTENTIAL", Reason: "UNDECIDED", TimeArrival: "", OdometerArrival: "", TimeDeparture: "", OdometerDeparture: "", NextVisitDate: "2025-09-11", Remarks: "Final decision call" },
  { VisitID: 46, ClientID: 13, DateOfVisit: "2025-03-12", Address: "Iloilo City, Iloilo", Touchpoint: 3, TouchpointType: "Visit", ClientType: "POTENTIAL", Reason: "FOR VERIFICATION", TimeArrival: "", OdometerArrival: "", TimeDeparture: "", OdometerDeparture: "", NextVisitDate: "2025-09-12", Remarks: "Document verification meeting" },
  { VisitID: 47, ClientID: 15, DateOfVisit: "2025-03-15", Address: "Quezon City, Metro Manila", Touchpoint: 3, TouchpointType: "Call", ClientType: "POTENTIAL", Reason: "INTERESTED", TimeArrival: "", OdometerArrival: "", TimeDeparture: "", OdometerDeparture: "", NextVisitDate: "2025-09-12", Remarks: "Requirements checklist review" },
  { VisitID: 48, ClientID: 16, DateOfVisit: "2025-03-12", Address: "Pasig City, Metro Manila", Touchpoint: 3, TouchpointType: "Visit", ClientType: "POTENTIAL", Reason: "INTERESTED", TimeArrival: "", OdometerArrival: "", TimeDeparture: "", OdometerDeparture: "", NextVisitDate: "2025-09-13", Remarks: "Application submission" },
  { VisitID: 49, ClientID: 19, DateOfVisit: "2025-03-20", Address: "Quezon City, Metro Manila", Touchpoint: 3, TouchpointType: "Call", ClientType: "POTENTIAL", Reason: "FOR VERIFICATION", TimeArrival: "", OdometerArrival: "", TimeDeparture: "", OdometerDeparture: "", NextVisitDate: "2025-09-14", Remarks: "Employment verification follow-up" },
  { VisitID: 50, ClientID: 21, DateOfVisit: "2025-03-14", Address: "Caloocan, Metro Manila", Touchpoint: 2, TouchpointType: "Visit", ClientType: "POTENTIAL", Reason: "INTERESTED", TimeArrival: "", OdometerArrival: "", TimeDeparture: "", OdometerDeparture: "", NextVisitDate: "2025-09-15", Remarks: "Application process initiation" },
  { VisitID: 51, ClientID: 22, DateOfVisit: "2025-03-05", Address: "San Mateo, Rizal", Touchpoint: 3, TouchpointType: "Call", ClientType: "POTENTIAL", Reason: "INTERESTED", TimeArrival: "", OdometerArrival: "", TimeDeparture: "", OdometerDeparture: "", NextVisitDate: "2025-09-16", Remarks: "Benefits explanation follow-up" },
  { VisitID: 52, ClientID: 25, DateOfVisit: "2025-03-18", Address: "Antipolo, Rizal", Touchpoint: 3, TouchpointType: "Visit", ClientType: "POTENTIAL", Reason: "INTERESTED", TimeArrival: "", OdometerArrival: "", TimeDeparture: "", OdometerDeparture: "", NextVisitDate: "2025-09-17", Remarks: "Document review and signing" },

  // Yesterday's completed visits (September 7, 2025) - 2 visits
  { VisitID: 53, ClientID: 1, DateOfVisit: "2025-09-07", Address: "Quezon City, Metro Manila", Touchpoint: 4, TouchpointType: "Visit", ClientType: "POTENTIAL", Reason: "INTERESTED", TimeArrival: "09:00", OdometerArrival: "12500", TimeDeparture: "09:45", OdometerDeparture: "12505", NextVisitDate: "", Remarks: "Client showed strong interest, provided all required documents" },
  { VisitID: 54, ClientID: 3, DateOfVisit: "2025-09-07", Address: "Legazpi City, Albay", Touchpoint: 5, TouchpointType: "Call", ClientType: "POTENTIAL", Reason: "FOR VERIFICATION", TimeArrival: "10:30", OdometerArrival: "", TimeDeparture: "10:45", OdometerDeparture: "", NextVisitDate: "", Remarks: "Verified employment status and eligibility" },

  // Today's visits (September 8, 2025) - 2 visits
  { VisitID: 55, ClientID: 10, DateOfVisit: "", Address: "Taguig, Metro Manila", Touchpoint: 6, TouchpointType: "Visit", ClientType: "EXISTING", Reason: "FOR UPDATE", TimeArrival: "10:00", OdometerArrival: "", TimeDeparture: "", OdometerDeparture: "", NextVisitDate: "2025-09-08", Remarks: "Scheduled to update beneficiary information" },
  { VisitID: 56, ClientID: 15, DateOfVisit: "", Address: "Quezon City, Metro Manila", Touchpoint: 3, TouchpointType: "Call", ClientType: "POTENTIAL", Reason: "INTERESTED", TimeArrival: "14:00", OdometerArrival: "", TimeDeparture: "", OdometerDeparture: "", NextVisitDate: "2025-09-08", Remarks: "Follow-up call to confirm interest and schedule document submission" },

  // Additional visits for clients who currently have no visits - adding varied reasons
  // Only keeping clients 37, 38, and 39 with NO ACTIVITY (they will have no visits)
  
  { VisitID: 57, ClientID: 36, DateOfVisit: "2025-02-10", Address: "Quezon City, Metro Manila", Touchpoint: 1, TouchpointType: "Visit", ClientType: "POTENTIAL", Reason: "INTERESTED", TimeArrival: "09:00", OdometerArrival: "12300", TimeDeparture: "09:45", OdometerDeparture: "12305", NextVisitDate: "2025-02-17", Remarks: "Client showed interest in pension benefits" },
  { VisitID: 58, ClientID: 40, DateOfVisit: "2025-02-15", Address: "Pampanga", Touchpoint: 1, TouchpointType: "Visit", ClientType: "POTENTIAL", Reason: "UNDECIDED", TimeArrival: "10:30", OdometerArrival: "45600", TimeDeparture: "11:15", OdometerDeparture: "45605", NextVisitDate: "2025-02-22", Remarks: "Needs time to think about the benefits" },
  { VisitID: 59, ClientID: 41, DateOfVisit: "2025-02-20", Address: "Batangas", Touchpoint: 1, TouchpointType: "Visit", ClientType: "EXISTING", Reason: "FOR VERIFICATION", TimeArrival: "14:00", OdometerArrival: "67800", TimeDeparture: "14:45", OdometerDeparture: "67805", NextVisitDate: "2025-02-27", Remarks: "Verifying spouse eligibility for benefits" },
  { VisitID: 60, ClientID: 42, DateOfVisit: "2025-03-01", Address: "Albay", Touchpoint: 1, TouchpointType: "Visit", ClientType: "POTENTIAL", Reason: "INTERESTED", TimeArrival: "08:30", OdometerArrival: "89100", TimeDeparture: "09:15", OdometerDeparture: "89105", NextVisitDate: "2025-03-08", Remarks: "Very interested in AFP Minor benefits" },
  { VisitID: 61, ClientID: 43, DateOfVisit: "2025-03-05", Address: "Nueva Ecija", Touchpoint: 1, TouchpointType: "Visit", ClientType: "POTENTIAL", Reason: "NOT INTERESTED", TimeArrival: "11:00", OdometerArrival: "12300", TimeDeparture: "11:15", OdometerDeparture: "12305", NextVisitDate: "", Remarks: "Not interested at this time" },
  { VisitID: 62, ClientID: 44, DateOfVisit: "2025-03-02", Address: "Iloilo", Touchpoint: 1, TouchpointType: "Visit", ClientType: "EXISTING", Reason: "FOR UPDATE", TimeArrival: "15:30", OdometerArrival: "45600", TimeDeparture: "16:15", OdometerDeparture: "45605", NextVisitDate: "2025-03-09", Remarks: "Updating pension details" },
  { VisitID: 63, ClientID: 45, DateOfVisit: "2025-02-28", Address: "Benguet", Touchpoint: 1, TouchpointType: "Visit", ClientType: "POTENTIAL", Reason: "LOAN INQUIRY", TimeArrival: "13:00", OdometerArrival: "67800", TimeDeparture: "13:45", OdometerDeparture: "67805", NextVisitDate: "2025-03-07", Remarks: "Inquired about loan options" },
  { VisitID: 64, ClientID: 46, DateOfVisit: "2025-03-04", Address: "Rizal", Touchpoint: 1, TouchpointType: "Visit", ClientType: "POTENTIAL", Reason: "INTERESTED", TimeArrival: "10:00", OdometerArrival: "89100", TimeDeparture: "10:45", OdometerDeparture: "89105", NextVisitDate: "2025-03-11", Remarks: "Interested in transferee benefits" },
  { VisitID: 65, ClientID: 47, DateOfVisit: "2025-02-18", Address: "Metro Manila", Touchpoint: 1, TouchpointType: "Visit", ClientType: "EXISTING", Reason: "FOR ADA COMPLIANCE", TimeArrival: "09:30", OdometerArrival: "12300", TimeDeparture: "10:15", OdometerDeparture: "12305", NextVisitDate: "2025-02-25", Remarks: "ADA compliance documentation" },
  { VisitID: 66, ClientID: 48, DateOfVisit: "2025-03-06", Address: "Rizal", Touchpoint: 1, TouchpointType: "Visit", ClientType: "POTENTIAL", Reason: "UNDECIDED", TimeArrival: "14:30", OdometerArrival: "45600", TimeDeparture: "15:15", OdometerDeparture: "45605", NextVisitDate: "2025-03-13", Remarks: "Still considering the options" },
  { VisitID: 67, ClientID: 49, DateOfVisit: "2025-02-25", Address: "Metro Manila", Touchpoint: 1, TouchpointType: "Visit", ClientType: "POTENTIAL", Reason: "INTERESTED", TimeArrival: "11:45", OdometerArrival: "67800", TimeDeparture: "12:30", OdometerDeparture: "67805", NextVisitDate: "2025-03-04", Remarks: "Ready to proceed with application" },
  { VisitID: 68, ClientID: 50, DateOfVisit: "2025-03-08", Address: "Pampanga", Touchpoint: 1, TouchpointType: "Visit", ClientType: "EXISTING", Reason: "FOR VERIFICATION", TimeArrival: "08:00", OdometerArrival: "89100", TimeDeparture: "08:45", OdometerDeparture: "89105", NextVisitDate: "2025-03-15", Remarks: "Verifying minor's school records" },
  { VisitID: 69, ClientID: 51, DateOfVisit: "2025-02-12", Address: "Batangas", Touchpoint: 1, TouchpointType: "Visit", ClientType: "POTENTIAL", Reason: "LOAN INQUIRY", TimeArrival: "16:00", OdometerArrival: "12300", TimeDeparture: "16:45", OdometerDeparture: "12305", NextVisitDate: "2025-02-19", Remarks: "Asked about loan terms and rates" },
  { VisitID: 70, ClientID: 52, DateOfVisit: "2025-03-01", Address: "Albay", Touchpoint: 1, TouchpointType: "Visit", ClientType: "EXISTING", Reason: "INTERESTED", TimeArrival: "12:00", OdometerArrival: "45600", TimeDeparture: "12:45", OdometerDeparture: "45605", NextVisitDate: "2025-03-08", Remarks: "Interested in additional coverage" },
  { VisitID: 71, ClientID: 53, DateOfVisit: "2025-02-22", Address: "Nueva Ecija", Touchpoint: 1, TouchpointType: "Visit", ClientType: "POTENTIAL", Reason: "NOT INTERESTED", TimeArrival: "10:15", OdometerArrival: "67800", TimeDeparture: "10:30", OdometerDeparture: "67805", NextVisitDate: "", Remarks: "Not interested in current offerings" },
  { VisitID: 72, ClientID: 54, DateOfVisit: "2025-03-03", Address: "Iloilo", Touchpoint: 1, TouchpointType: "Visit", ClientType: "POTENTIAL", Reason: "INTERESTED", TimeArrival: "13:30", OdometerArrival: "89100", TimeDeparture: "14:15", OdometerDeparture: "89105", NextVisitDate: "2025-03-10", Remarks: "Very positive response to pension presentation" },
  { VisitID: 73, ClientID: 55, DateOfVisit: "2025-02-16", Address: "Benguet", Touchpoint: 1, TouchpointType: "Visit", ClientType: "EXISTING", Reason: "FOR UPDATE", TimeArrival: "09:45", OdometerArrival: "12300", TimeDeparture: "10:30", OdometerDeparture: "12305", NextVisitDate: "2025-02-23", Remarks: "Annual pension update" },
  { VisitID: 74, ClientID: 56, DateOfVisit: "2025-03-07", Address: "Rizal", Touchpoint: 1, TouchpointType: "Visit", ClientType: "EXISTING", Reason: "FOR ADA COMPLIANCE", TimeArrival: "15:00", OdometerArrival: "45600", TimeDeparture: "15:45", OdometerDeparture: "45605", NextVisitDate: "2025-03-14", Remarks: "ADA compliance review" },
  { VisitID: 75, ClientID: 57, DateOfVisit: "2025-02-14", Address: "Pampanga", Touchpoint: 1, TouchpointType: "Visit", ClientType: "POTENTIAL", Reason: "UNDECIDED", TimeArrival: "11:30", OdometerArrival: "67800", TimeDeparture: "12:15", OdometerDeparture: "67805", NextVisitDate: "2025-02-21", Remarks: "Needs spousal approval" },
  { VisitID: 76, ClientID: 58, DateOfVisit: "2025-03-05", Address: "Batangas", Touchpoint: 1, TouchpointType: "Visit", ClientType: "EXISTING", Reason: "FOR VERIFICATION", TimeArrival: "14:45", OdometerArrival: "89100", TimeDeparture: "15:30", OdometerDeparture: "89105", NextVisitDate: "2025-03-12", Remarks: "Verifying transferee status" },
  { VisitID: 77, ClientID: 59, DateOfVisit: "2025-02-26", Address: "Albay", Touchpoint: 1, TouchpointType: "Visit", ClientType: "POTENTIAL", Reason: "INTERESTED", TimeArrival: "08:30", OdometerArrival: "12300", TimeDeparture: "09:15", OdometerDeparture: "12305", NextVisitDate: "2025-03-05", Remarks: "Interested in retiree benefits" },
  { VisitID: 78, ClientID: 60, DateOfVisit: "2025-03-02", Address: "Nueva Ecija", Touchpoint: 1, TouchpointType: "Visit", ClientType: "POTENTIAL", Reason: "LOAN INQUIRY", TimeArrival: "16:15", OdometerArrival: "45600", TimeDeparture: "17:00", OdometerDeparture: "45605", NextVisitDate: "2025-03-09", Remarks: "Inquired about loan requirements" },

  // Continue adding visits for remaining clients (61-90), keeping only 37, 38, 39 without visits
  { VisitID: 79, ClientID: 61, DateOfVisit: "2025-02-08", Address: "Iloilo", Touchpoint: 1, TouchpointType: "Visit", ClientType: "POTENTIAL", Reason: "INTERESTED", TimeArrival: "10:00", OdometerArrival: "67800", TimeDeparture: "10:45", OdometerDeparture: "67805", NextVisitDate: "2025-02-15", Remarks: "Interested in pension coverage" },
  { VisitID: 80, ClientID: 62, DateOfVisit: "2025-02-19", Address: "Benguet", Touchpoint: 1, TouchpointType: "Visit", ClientType: "EXISTING", Reason: "FOR UPDATE", TimeArrival: "13:00", OdometerArrival: "89100", TimeDeparture: "13:45", OdometerDeparture: "89105", NextVisitDate: "2025-02-26", Remarks: "Updating minor beneficiary info" },
  { VisitID: 81, ClientID: 63, DateOfVisit: "2025-03-01", Address: "Rizal", Touchpoint: 1, TouchpointType: "Visit", ClientType: "POTENTIAL", Reason: "UNDECIDED", TimeArrival: "09:30", OdometerArrival: "12300", TimeDeparture: "10:15", OdometerDeparture: "12305", NextVisitDate: "2025-03-08", Remarks: "Comparing with other providers" },
  { VisitID: 82, ClientID: 64, DateOfVisit: "2025-02-24", Address: "Pampanga", Touchpoint: 1, TouchpointType: "Visit", ClientType: "EXISTING", Reason: "FOR ADA COMPLIANCE", TimeArrival: "14:30", OdometerArrival: "45600", TimeDeparture: "15:15", OdometerDeparture: "45605", NextVisitDate: "2025-03-03", Remarks: "ADA documentation submission" },
  { VisitID: 83, ClientID: 65, DateOfVisit: "2025-03-04", Address: "Batangas", Touchpoint: 1, TouchpointType: "Visit", ClientType: "POTENTIAL", Reason: "INTERESTED", TimeArrival: "11:15", OdometerArrival: "67800", TimeDeparture: "12:00", OdometerDeparture: "67805", NextVisitDate: "2025-03-11", Remarks: "Ready to start pension application" },
  { VisitID: 84, ClientID: 66, DateOfVisit: "2025-02-17", Address: "Albay", Touchpoint: 1, TouchpointType: "Visit", ClientType: "POTENTIAL", Reason: "NOT INTERESTED", TimeArrival: "15:45", OdometerArrival: "89100", TimeDeparture: "16:00", OdometerDeparture: "89105", NextVisitDate: "", Remarks: "Not interested at this time" },
  { VisitID: 85, ClientID: 67, DateOfVisit: "2025-03-06", Address: "Nueva Ecija", Touchpoint: 1, TouchpointType: "Visit", ClientType: "EXISTING", Reason: "FOR VERIFICATION", TimeArrival: "08:45", OdometerArrival: "12300", TimeDeparture: "09:30", OdometerDeparture: "12305", NextVisitDate: "2025-03-13", Remarks: "Verifying retiree status" },
  { VisitID: 86, ClientID: 68, DateOfVisit: "2025-02-11", Address: "Iloilo", Touchpoint: 1, TouchpointType: "Visit", ClientType: "POTENTIAL", Reason: "LOAN INQUIRY", TimeArrival: "12:30", OdometerArrival: "45600", TimeDeparture: "13:15", OdometerDeparture: "45605", NextVisitDate: "2025-02-18", Remarks: "Asked about loan interest rates" },
  { VisitID: 87, ClientID: 69, DateOfVisit: "2025-03-08", Address: "Benguet", Touchpoint: 1, TouchpointType: "Visit", ClientType: "EXISTING", Reason: "INTERESTED", TimeArrival: "10:30", OdometerArrival: "67800", TimeDeparture: "11:15", OdometerDeparture: "67805", NextVisitDate: "2025-03-15", Remarks: "Interested in upgrading coverage" },
  { VisitID: 88, ClientID: 70, DateOfVisit: "2025-02-21", Address: "Rizal", Touchpoint: 1, TouchpointType: "Visit", ClientType: "POTENTIAL", Reason: "UNDECIDED", TimeArrival: "14:00", OdometerArrival: "89100", TimeDeparture: "14:45", OdometerDeparture: "89105", NextVisitDate: "2025-02-28", Remarks: "Still evaluating options" },
  { VisitID: 89, ClientID: 71, DateOfVisit: "2025-03-03", Address: "Pampanga", Touchpoint: 1, TouchpointType: "Visit", ClientType: "POTENTIAL", Reason: "INTERESTED", TimeArrival: "16:30", OdometerArrival: "12300", TimeDeparture: "17:15", OdometerDeparture: "12305", NextVisitDate: "2025-03-10", Remarks: "Very interested in AFP pension" },
  { VisitID: 90, ClientID: 72, DateOfVisit: "2025-02-13", Address: "Batangas", Touchpoint: 1, TouchpointType: "Visit", ClientType: "EXISTING", Reason: "FOR UPDATE", TimeArrival: "09:00", OdometerArrival: "45600", TimeDeparture: "09:45", OdometerDeparture: "45605", NextVisitDate: "2025-02-20", Remarks: "Updating spouse information" },
  { VisitID: 91, ClientID: 73, DateOfVisit: "2025-02-27", Address: "Albay", Touchpoint: 1, TouchpointType: "Visit", ClientType: "POTENTIAL", Reason: "FOR VERIFICATION", TimeArrival: "11:00", OdometerArrival: "67800", TimeDeparture: "11:45", OdometerDeparture: "67805", NextVisitDate: "2025-03-06", Remarks: "Verifying employment records" },
  { VisitID: 92, ClientID: 74, DateOfVisit: "2025-03-05", Address: "Nueva Ecija", Touchpoint: 1, TouchpointType: "Visit", ClientType: "EXISTING", Reason: "FOR ADA COMPLIANCE", TimeArrival: "13:30", OdometerArrival: "89100", TimeDeparture: "14:15", OdometerDeparture: "89105", NextVisitDate: "2025-03-12", Remarks: "ADA compliance review" },
  { VisitID: 93, ClientID: 75, DateOfVisit: "2025-02-09", Address: "Iloilo", Touchpoint: 1, TouchpointType: "Visit", ClientType: "POTENTIAL", Reason: "INTERESTED", TimeArrival: "15:15", OdometerArrival: "12300", TimeDeparture: "16:00", OdometerDeparture: "12305", NextVisitDate: "2025-02-16", Remarks: "Interested in pension benefits" },
  { VisitID: 94, ClientID: 76, DateOfVisit: "2025-03-07", Address: "Benguet", Touchpoint: 1, TouchpointType: "Visit", ClientType: "EXISTING", Reason: "INTERESTED", TimeArrival: "08:15", OdometerArrival: "45600", TimeDeparture: "09:00", OdometerDeparture: "45605", NextVisitDate: "2025-03-14", Remarks: "Interested in additional benefits" },
  { VisitID: 95, ClientID: 77, DateOfVisit: "2025-02-23", Address: "Rizal", Touchpoint: 1, TouchpointType: "Visit", ClientType: "POTENTIAL", Reason: "LOAN INQUIRY", TimeArrival: "12:00", OdometerArrival: "67800", TimeDeparture: "12:45", OdometerDeparture: "67805", NextVisitDate: "2025-03-02", Remarks: "Inquired about loan processes" },
  { VisitID: 96, ClientID: 78, DateOfVisit: "2025-03-01", Address: "Pampanga", Touchpoint: 1, TouchpointType: "Visit", ClientType: "EXISTING", Reason: "FOR VERIFICATION", TimeArrival: "10:45", OdometerArrival: "89100", TimeDeparture: "11:30", OdometerDeparture: "89105", NextVisitDate: "2025-03-08", Remarks: "Verifying minor eligibility" },
  { VisitID: 97, ClientID: 79, DateOfVisit: "2025-02-18", Address: "Batangas", Touchpoint: 1, TouchpointType: "Visit", ClientType: "POTENTIAL", Reason: "UNDECIDED", TimeArrival: "14:15", OdometerArrival: "12300", TimeDeparture: "15:00", OdometerDeparture: "12305", NextVisitDate: "2025-02-25", Remarks: "Needs more time to decide" },
  { VisitID: 98, ClientID: 80, DateOfVisit: "2025-03-04", Address: "Albay", Touchpoint: 1, TouchpointType: "Visit", ClientType: "POTENTIAL", Reason: "INTERESTED", TimeArrival: "16:45", OdometerArrival: "45600", TimeDeparture: "17:30", OdometerDeparture: "45605", NextVisitDate: "2025-03-11", Remarks: "Very interested in posthumous benefits" },
  { VisitID: 99, ClientID: 81, DateOfVisit: "2025-02-20", Address: "Nueva Ecija", Touchpoint: 1, TouchpointType: "Visit", ClientType: "EXISTING", Reason: "FOR UPDATE", TimeArrival: "09:30", OdometerArrival: "67800", TimeDeparture: "10:15", OdometerDeparture: "67805", NextVisitDate: "2025-02-27", Remarks: "Updating spouse details" },
  { VisitID: 100, ClientID: 82, DateOfVisit: "2025-03-06", Address: "Iloilo", Touchpoint: 1, TouchpointType: "Visit", ClientType: "POTENTIAL", Reason: "NOT INTERESTED", TimeArrival: "11:30", OdometerArrival: "89100", TimeDeparture: "11:45", OdometerDeparture: "89105", NextVisitDate: "", Remarks: "Not interested in current products" },
  { VisitID: 101, ClientID: 83, DateOfVisit: "2025-02-15", Address: "Benguet", Touchpoint: 1, TouchpointType: "Visit", ClientType: "POTENTIAL", Reason: "INTERESTED", TimeArrival: "13:45", OdometerArrival: "12300", TimeDeparture: "14:30", OdometerDeparture: "12305", NextVisitDate: "2025-02-22", Remarks: "Ready to proceed with pension" },
  { VisitID: 102, ClientID: 84, DateOfVisit: "2025-03-02", Address: "Rizal", Touchpoint: 1, TouchpointType: "Visit", ClientType: "EXISTING", Reason: "FOR ADA COMPLIANCE", TimeArrival: "15:00", OdometerArrival: "45600", TimeDeparture: "15:45", OdometerDeparture: "45605", NextVisitDate: "2025-03-09", Remarks: "ADA compliance documentation" },
  { VisitID: 103, ClientID: 85, DateOfVisit: "2025-02-28", Address: "Pampanga", Touchpoint: 1, TouchpointType: "Visit", ClientType: "POTENTIAL", Reason: "FOR VERIFICATION", TimeArrival: "08:00", OdometerArrival: "67800", TimeDeparture: "08:45", OdometerDeparture: "67805", NextVisitDate: "2025-03-07", Remarks: "Verifying retiree eligibility" },
  { VisitID: 104, ClientID: 86, DateOfVisit: "2025-03-08", Address: "Batangas", Touchpoint: 1, TouchpointType: "Visit", ClientType: "EXISTING", Reason: "INTERESTED", TimeArrival: "12:15", OdometerArrival: "89100", TimeDeparture: "13:00", OdometerDeparture: "89105", NextVisitDate: "2025-03-15", Remarks: "Interested in upgrading minor coverage" },
  { VisitID: 105, ClientID: 87, DateOfVisit: "2025-02-12", Address: "Albay", Touchpoint: 1, TouchpointType: "Visit", ClientType: "POTENTIAL", Reason: "LOAN INQUIRY", TimeArrival: "10:30", OdometerArrival: "12300", TimeDeparture: "11:15", OdometerDeparture: "12305", NextVisitDate: "2025-02-19", Remarks: "Asked about transferee loan options" },
  { VisitID: 106, ClientID: 88, DateOfVisit: "2025-03-03", Address: "Nueva Ecija", Touchpoint: 1, TouchpointType: "Visit", ClientType: "EXISTING", Reason: "FOR UPDATE", TimeArrival: "14:30", OdometerArrival: "45600", TimeDeparture: "15:15", OdometerDeparture: "45605", NextVisitDate: "2025-03-10", Remarks: "Annual transferee update" },
  { VisitID: 107, ClientID: 89, DateOfVisit: "2025-02-25", Address: "Iloilo", Touchpoint: 1, TouchpointType: "Visit", ClientType: "POTENTIAL", Reason: "UNDECIDED", TimeArrival: "16:00", OdometerArrival: "67800", TimeDeparture: "16:45", OdometerDeparture: "67805", NextVisitDate: "2025-03-04", Remarks: "Still considering retiree options" },
  { VisitID: 108, ClientID: 90, DateOfVisit: "2025-03-07", Address: "Benguet", Touchpoint: 1, TouchpointType: "Visit", ClientType: "POTENTIAL", Reason: "INTERESTED", TimeArrival: "09:15", OdometerArrival: "89100", TimeDeparture: "10:00", OdometerDeparture: "89105", NextVisitDate: "2025-03-14", Remarks: "Very interested in spouse benefits" }
];

export class DataService {
  static getClients(): Client[] {
    return clientsData;
  }

  static getClientById(id: number): Client | undefined {
    return clientsData.find(client => client.ClientID === id);
  }

  static getClientDetails(id: number): ClientDetails | undefined {
    const client = this.getClientById(id);
    if (!client) return undefined;

    const addresses = addressesData.filter(addr => addr.ClientID === id);
    const phoneNumbers = phoneNumbersData.filter(phone => phone.ClientID === id);
    const visits = visitsData.filter(visit => visit.ClientID === id);
    
    // Get assigned caravan
    const caravanAssignment = caravanClientsData.find(cc => cc.ClientID === id && cc.IsActive);
    const caravan = caravanAssignment ? caravansData.find(c => c.CaravanID === caravanAssignment.CaravanID) : undefined;
    
    // Get the most recent meaningful visit reason (excluding contact issues)
    const sortedVisits = visits.sort((a, b) => new Date(b.DateOfVisit).getTime() - new Date(a.DateOfVisit).getTime());
    
    // Find the most recent visit that has a meaningful reason (not contact issues)
    const contactIssues = ['NOT AROUND', 'NO ANSWER', 'UNAVAILABLE'];
    const meaningfulVisit = sortedVisits.find(visit => 
      visit.Reason && !contactIssues.includes(visit.Reason)
    );
    
    const currentReason = meaningfulVisit ? meaningfulVisit.Reason : 
                         (sortedVisits.length > 0 ? sortedVisits[0].Reason : undefined);
    const isInterested = currentReason === "INTERESTED";

    return {
      ...client,
      addresses,
      phoneNumbers,
      visits,
      currentReason,
      isInterested,
      caravan
    };
  }

  static getAllClientDetails(): ClientDetails[] {
    return clientsData.map(client => this.getClientDetails(client.ClientID)!);
  }

  static getVisitsByClientId(clientId: number): Visit[] {
    return visitsData.filter(visit => visit.ClientID === clientId);
  }

  static getClientsByFilter(filter: {
    clientType?: string;
    interestedOnly?: boolean;
    reason?: string;
  }): ClientDetails[] {
    let clients = this.getAllClientDetails();

    if (filter.clientType && filter.clientType !== 'ALL') {
      clients = clients.filter(client => client.ClientType === filter.clientType);
    }

    if (filter.interestedOnly) {
      clients = clients.filter(client => client.isInterested);
    }

    if (filter.reason && filter.reason !== 'ALL') {
      clients = clients.filter(client => client.currentReason === filter.reason);
    }

    return clients;
  }

  static getReasons(): string[] {
    const reasons = [...new Set(visitsData.map(visit => visit.Reason))];
    return reasons.sort();
  }

  static getClientTypes(): string[] {
    const types = [...new Set(clientsData.map(client => client.ClientType))];
    return types.sort();
  }

  static getMarketTypes(): string[] {
    return [
      'VIRGIN',
      'EXISTING', 
      'FULLYPAID',
      'OTHERS'
    ];
  }

  static getProductTypes(): string[] {
    return [
      'AFP MINOR',
      'AFP PENSION',
      'BFP ACTIVE',
      'BFP PENSION',
      'BFP STP',
      'NAPOLCOM',
      'PNP INP',
      'OTHERS',
      'UNCATEGORIZED'
    ];
  }

  static getPensionTypes(): string[] {
    return [
      'POSTHUMOUS-MINOR',
      'POSTHUMOUS-SPOUSE',
      'RETIREE-OPTIONAL',
      'RETIREE-COMPULSORY',
      'TPPD-RETIREE',
      'TPPD-SPOUSE',
      'TRANSFEREE-MINOR',
      'TRANSFEREE-SPOUSE'
    ];
  }

  static getCaravans(): Caravan[] {
    return caravansData.filter(caravan => caravan.IsActive);
  }

  static getCaravanNames(): string[] {
    return caravansData
      .filter(caravan => caravan.IsActive)
      .map(caravan => caravan.FullName)
      .sort();
  }

  static getMunicipalities(): string[] {
    const municipalities = [...new Set(addressesData.map(addr => addr.Municipality))];
    return municipalities.sort();
  }

  static addClient(clientData: {
    fullName: string;
    productType: string;
    marketType: string;
    clientType: string;
    pensionType: string;
    age: number;
    birthday: string;
    gmail: string;
    facebookLink: string;
    street: string;
    municipality: string;
    province: string;
    phoneNumber: string;
  }): Client {
    // Generate new ClientID
    const maxClientID = Math.max(...clientsData.map(client => client.ClientID));
    const newClientID = maxClientID + 1;
    
    // Generate PAN
    const pan = `2024${String(newClientID).padStart(6, '0')}`;

    // Create new client
    const newClient: Client = {
      ClientID: newClientID,
      FullName: clientData.fullName,
      ProductType: clientData.productType,
      MarketType: clientData.marketType,
      ClientType: clientData.clientType,
      PensionType: clientData.pensionType,
      PAN: pan,
      Age: clientData.age,
      Birthday: clientData.birthday,
      Gmail: clientData.gmail,
      FacebookLink: clientData.facebookLink
    };

    // Add client to data
    clientsData.push(newClient);

    // Add default address
    const newAddressID = Math.max(...addressesData.map(addr => addr.AddressID)) + 1;
    const newAddress: Address = {
      AddressID: newAddressID,
      ClientID: newClientID,
      Street: clientData.street,
      Municipality: clientData.municipality,
      Province: clientData.province,
      IsDefault: true
    };
    addressesData.push(newAddress);

    // Add phone number
    const newPhoneID = Math.max(...phoneNumbersData.map(phone => phone.PhoneID)) + 1;
    const newPhone: PhoneNumber = {
      PhoneID: newPhoneID,
      ClientID: newClientID,
      PhoneNumber: clientData.phoneNumber,
      IsPrimary: true
    };
    phoneNumbersData.push(newPhone);

    return newClient;
  }
}