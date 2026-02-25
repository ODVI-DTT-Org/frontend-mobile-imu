import { useState, useMemo } from "react";
import { 
  Search, 
  Filter, 
  Plus, 
  Download,
  BarChart3,
  Users,
  Car,
  UsersRound,
  Calendar,
  FileCheck,
  UserCheck,
  FileText,
  Shield,
  Eye,
  Crown,
  UserMinus,
  CheckCircle,
  XCircle,
  Clock,
  MapPin,
  Activity,
  TrendingUp,
  TrendingDown,
  DollarSign,
  Target,
  AlertTriangle,
  Info,
  UserPlus,
  Settings,
  LogIn,
  LogOut,
  Database,
  Edit,
  Trash2
} from "lucide-react";
import logoImage from 'figma:asset/7106e387a0150aacb8a44d58c73d2158ededf89d.png';
import { Button } from "./ui/button";
import { Input } from "./ui/input";
import { Badge } from "./ui/badge";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "./ui/table";
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuLabel, DropdownMenuSeparator, DropdownMenuTrigger, DropdownMenuCheckboxItem } from "./ui/dropdown-menu";
import { Accordion, AccordionContent, AccordionItem, AccordionTrigger } from "./ui/accordion";
import { Tooltip, TooltipContent, TooltipProvider, TooltipTrigger } from "./ui/tooltip";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "./ui/card";
import { Progress } from "./ui/progress";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "./ui/select";
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, ResponsiveContainer, PieChart, Pie, Cell, LineChart, Line, Area, AreaChart, Legend } from 'recharts';
import { DataService, ClientDetails } from "../services/DataService";
import { CaravanDetailModal } from "./CaravanDetailModal";

interface DesktopClientsProps {
  onLogout?: () => void;
}

interface FilterState {
  clientType: string[];
  touchpoint: string[];
  caravan: string[];
  municipality: string[];
  market: string[];
  product: string[];
  pension: string[];
}

export function DesktopClients({ onLogout }: DesktopClientsProps) {
  const [activeTab, setActiveTab] = useState('dashboard');
  const [searchQuery, setSearchQuery] = useState('');
  const [filters, setFilters] = useState<FilterState>({
    clientType: [],
    touchpoint: [],
    caravan: [],
    municipality: [],
    market: [],
    product: [],
    pension: []
  });
  const [selectedCaravanMember, setSelectedCaravanMember] = useState<any>(null);
  const [isCaravanModalOpen, setIsCaravanModalOpen] = useState(false);

  // Get all client data
  const allClients = useMemo(() => DataService.getAllClientDetails(), []);

  // Get unique filter values from data
  const filterOptions = useMemo(() => {
    const municipalities = DataService.getMunicipalities();
    const markets = DataService.getMarketTypes();
    const products = DataService.getProductTypes();
    const pensions = DataService.getPensionTypes();
    const clientTypes = DataService.getClientTypes();
    const caravans = DataService.getCaravanNames();
    
    // Get touchpoint numbers from visits
    const touchpoints = [...new Set(allClients.flatMap(client => 
      client.visits.map(visit => visit.Touchpoint.toString())
    ))].sort((a, b) => parseInt(a) - parseInt(b));

    return {
      municipalities,
      markets,
      products,
      pensions,
      clientTypes,
      touchpoints,
      caravans
    };
  }, [allClients]);

  // Caravan team data
  const caravanTeams = useMemo(() => {
    const teams = {
      "NORTH AGUILA TEAM": [
        { firstName: "MELCHOR", lastName: "QUINTO" },
        { firstName: "ABELARDO", lastName: "NUQUI" },
        { firstName: "CHRISTOPHER", lastName: "DELACRUZ" },
        { firstName: "GODWIN", lastName: "RUIZ" },
        { firstName: "HILARIO JR.", lastName: "GARCIA" },
        { firstName: "JONNEL", lastName: "MANIO" },
        { firstName: "JAN NIÑO BOI F.", lastName: "URBANO" },
        { firstName: "MARK", lastName: "DEL MORO" },
        { firstName: "MARIO", lastName: "RESURRECION" }
      ],
      "UNSTOPPABLE TEAM": [
        { firstName: "MARK ANTHONY", lastName: "ALVAREZ" },
        { firstName: "BOYNEIL", lastName: "MALIWAT" },
        { firstName: "DARWIN", lastName: "MAGTANGOB" },
        { firstName: "ERVEN", lastName: "ESPELIMBERGO" },
        { firstName: "EDWARD", lastName: "SEVILLENA" },
        { firstName: "JOHNSON", lastName: "BERCE" },
        { firstName: "JORIS", lastName: "LUCILO" },
        { firstName: "JOEL", lastName: "OPLE" },
        { firstName: "ROLAND", lastName: "ODI" },
        { firstName: "RICARDO C.", lastName: "VERDE" }
      ],
      "GENERALS TEAM": [
        { firstName: "NOLAN", lastName: "DELROSARIO" },
        { firstName: "FRANCIS NIEL", lastName: "DULLER" },
        { firstName: "HARVEY C.", lastName: "TORREFIEL" },
        { firstName: "JOSEPH RAFAEL", lastName: "GARCIA" },
        { firstName: "MARK KEVIN", lastName: "GERMAN" },
        { firstName: "MARLON", lastName: "DEBORDE" },
        { firstName: "YURI", lastName: "FABRID" }
      ],
      "EXPLORER REBORN TEAM": [
        { firstName: "ALEXANDER JR.", lastName: "AVENIDO" },
        { firstName: "ALBERTO", lastName: "ANACIO" },
        { firstName: "JONYBOY", lastName: "GERONCA" },
        { firstName: "NILO", lastName: "LOPEZ" },
        { firstName: "ROWEL", lastName: "PALAMOS" },
        { firstName: "ROLANDO", lastName: "SARMIENTO JR." },
        { firstName: "RAMSES", lastName: "RANADA" }
      ],
      "WARRIORS TEAM": [
        { firstName: "PETER PAUL", lastName: "CELESTE" },
        { firstName: "AERON", lastName: "ANGELES" },
        { firstName: "GLENNMAR", lastName: "CALAIN" },
        { firstName: "JEFFREY", lastName: "HECHANOVA" },
        { firstName: "JOHN RAY", lastName: "SINGSON" },
        { firstName: "KENNY-LYN", lastName: "AVILA" },
        { firstName: "NECOLUID", lastName: "QUIOKELES" }
      ],
      "SULTANS TEAM": [
        { firstName: "GEOFFREY", lastName: "MORENO" },
        { firstName: "ARCHIE", lastName: "SUMAGANG" },
        { firstName: "GEORGE", lastName: "REMOLADO" },
        { firstName: "MARVIN", lastName: "BALANUECO" },
        { firstName: "EDWIN", lastName: "MANGAY-AYAM" }
      ]
    };

    // Convert to flat array with team information
    return Object.entries(teams).flatMap(([teamName, members]) =>
      members.map(member => ({
        firstName: member.firstName,
        lastName: member.lastName,
        username: member.firstName.charAt(0).toLowerCase() + member.lastName.toLowerCase().replace(/[^a-zA-Z]/g, ''),
        email: member.lastName.toLowerCase().replace(/[^a-zA-Z]/g, '') + '@gmail.com',
        group: teamName
      }))
    );
  }, []);

  // Dashboard data
  const dashboardData = useMemo(() => {
    // Client distribution by market type
    const marketData = Object.entries(
      allClients.reduce((acc, client) => {
        acc[client.MarketType] = (acc[client.MarketType] || 0) + 1;
        return acc;
      }, {} as Record<string, number>)
    ).map(([name, value]) => ({ name, value }));

    // Monthly visit trends
    const monthlyVisits = Array.from({ length: 12 }, (_, i) => {
      const month = new Date(2024, i, 1).toLocaleDateString('en-US', { month: 'short' });
      const visits = Math.floor(Math.random() * 500) + 200;
      return { month, visits, clients: Math.floor(visits * 0.7) };
    });

    // Caravan performance
    const caravanPerformance = filterOptions.caravans.slice(0, 10).map(caravan => ({
      name: caravan.split(' ').slice(0, 2).join(' '),
      clients: Math.floor(Math.random() * 20) + 5,
      visits: Math.floor(Math.random() * 50) + 10,
      completion: Math.floor(Math.random() * 30) + 70
    }));

    // Touchpoint progress
    const touchpointData = Array.from({ length: 7 }, (_, i) => ({
      touchpoint: `TP ${i + 1}`,
      completed: Math.floor(Math.random() * 80) + 20,
      pending: Math.floor(Math.random() * 30) + 10
    }));

    return {
      marketData,
      monthlyVisits,
      caravanPerformance,
      touchpointData,
      totalClients: allClients.length,
      activeCaravans: filterOptions.caravans.length,
      completedVisits: allClients.reduce((acc, client) => acc + client.visits.length, 0),
      pendingApprovals: Math.floor(Math.random() * 50) + 20
    };
  }, [allClients, filterOptions]);

  // Attendance data
  const attendanceData = useMemo(() => {
    const today = new Date();
    const thisWeek = Array.from({ length: 7 }, (_, i) => {
      const date = new Date(today);
      date.setDate(today.getDate() - i);
      return date.toLocaleDateString('en-US', { weekday: 'short', month: 'short', day: 'numeric' });
    }).reverse();

    return caravanTeams.map(member => ({
      ...member,
      attendance: thisWeek.map(date => ({
        date,
        status: Math.random() > 0.2 ? 'present' : Math.random() > 0.5 ? 'late' : 'absent',
        timeIn: Math.random() > 0.2 ? `${Math.floor(Math.random() * 2) + 7}:${String(Math.floor(Math.random() * 60)).padStart(2, '0')} AM` : null,
        timeOut: Math.random() > 0.2 ? `${Math.floor(Math.random() * 3) + 5}:${String(Math.floor(Math.random() * 60)).padStart(2, '0')} PM` : null
      }))
    }));
  }, [caravanTeams]);

  // Audit trail data
  const auditTrailData = useMemo(() => {
    const actions = [
      { action: 'LOGIN', description: 'User logged into the system', user: 'John Doe', severity: 'INFO' },
      { action: 'CLIENT_CREATE', description: 'New client record created', user: 'Jane Smith', severity: 'INFO' },
      { action: 'CLIENT_UPDATE', description: 'Client information updated', user: 'Mike Johnson', severity: 'INFO' },
      { action: 'VISIT_SCHEDULE', description: 'Visit scheduled for client', user: 'Sarah Wilson', severity: 'INFO' },
      { action: 'APPROVAL_REQUEST', description: 'Approval request submitted', user: 'Tom Brown', severity: 'WARNING' },
      { action: 'APPROVAL_GRANTED', description: 'Approval request granted', user: 'Admin User', severity: 'INFO' },
      { action: 'DATA_EXPORT', description: 'Client data exported to CSV', user: 'Manager User', severity: 'WARNING' },
      { action: 'SYSTEM_BACKUP', description: 'System backup completed', user: 'System', severity: 'INFO' },
      { action: 'LOGIN_FAILED', description: 'Failed login attempt detected', user: 'Unknown', severity: 'ERROR' },
      { action: 'PERMISSION_DENIED', description: 'Unauthorized access attempt', user: 'John Doe', severity: 'ERROR' },
      { action: 'CARAVAN_ASSIGN', description: 'Client assigned to caravan', user: 'Team Lead', severity: 'INFO' },
      { action: 'TOUCHPOINT_COMPLETE', description: 'Touchpoint marked as completed', user: 'Field Agent', severity: 'INFO' }
    ];

    return Array.from({ length: 50 }, (_, i) => {
      const action = actions[Math.floor(Math.random() * actions.length)];
      const timestamp = new Date();
      timestamp.setMinutes(timestamp.getMinutes() - (i * Math.floor(Math.random() * 60) + 5));
      
      return {
        id: `LOG_${String(i + 1).padStart(4, '0')}`,
        timestamp: timestamp.toISOString(),
        ...action,
        ipAddress: `192.168.1.${Math.floor(Math.random() * 255)}`,
        module: action.action.includes('CLIENT') ? 'Client Management' : 
                action.action.includes('VISIT') ? 'Visit Management' :
                action.action.includes('APPROVAL') ? 'Approval System' :
                action.action.includes('LOGIN') || action.action.includes('PERMISSION') ? 'Authentication' :
                'System'
      };
    });
  }, []);

  // Groups data structure
  const groupsData = useMemo(() => {
    return {
      "NORTH REGION": {
        description: "Northern territories operations",
        teams: ["NORTH AGUILA TEAM", "UNSTOPPABLE TEAM"]
      },
      "CENTRAL REGION": {
        description: "Central territories operations", 
        teams: ["GENERALS TEAM", "EXPLORER REBORN TEAM"]
      },
      "SOUTH REGION": {
        description: "Southern territories operations",
        teams: ["WARRIORS TEAM", "SULTANS TEAM"]
      }
    };
  }, []);

  // Get team members for groups with position
  const getGroupTeamMembers = (teamName: string) => {
    const teamMembers = caravanTeams.filter(member => member.group === teamName);
    return teamMembers.map((member, index) => ({
      ...member,
      position: index === 0 ? 'Leader' : 'Member',
      isLeader: index === 0
    }));
  };

  // Filter clients based on search and filters
  const filteredClients = useMemo(() => {
    let filtered = allClients;

    // Search filter
    if (searchQuery) {
      filtered = filtered.filter(client => 
        client.FullName.toLowerCase().includes(searchQuery.toLowerCase()) ||
        client.PAN.toLowerCase().includes(searchQuery.toLowerCase()) ||
        client.addresses.some(addr => 
          addr.Street.toLowerCase().includes(searchQuery.toLowerCase()) ||
          addr.Municipality.toLowerCase().includes(searchQuery.toLowerCase())
        )
      );
    }

    // Apply filters
    if (filters.clientType.length > 0) {
      filtered = filtered.filter(client => filters.clientType.includes(client.ClientType));
    }
    if (filters.municipality.length > 0) {
      filtered = filtered.filter(client => 
        client.addresses.some(addr => filters.municipality.includes(addr.Municipality))
      );
    }
    if (filters.market.length > 0) {
      filtered = filtered.filter(client => filters.market.includes(client.MarketType));
    }
    if (filters.product.length > 0) {
      filtered = filtered.filter(client => filters.product.includes(client.ProductType));
    }
    if (filters.pension.length > 0) {
      filtered = filtered.filter(client => filters.pension.includes(client.PensionType));
    }
    if (filters.touchpoint.length > 0) {
      filtered = filtered.filter(client => 
        client.visits.some(visit => filters.touchpoint.includes(visit.Touchpoint.toString()))
      );
    }
    if (filters.caravan.length > 0) {
      filtered = filtered.filter(client => 
        client.caravan && filters.caravan.includes(client.caravan.FullName)
      );
    }

    return filtered;
  }, [allClients, searchQuery, filters]);

  const sidebarItems = [
    { key: 'dashboard', label: 'Dashboard', icon: BarChart3 },
    { key: 'clients', label: 'Clients', icon: Users },
    { key: 'caravan', label: 'Caravan', icon: Car },
    { key: 'groups', label: 'Groups', icon: UsersRound },
    { key: 'attendance', label: 'Attendance', icon: Calendar },
    { key: 'approvals', label: 'Approvals', icon: FileCheck },
    { key: 'users', label: 'Users', icon: UserCheck },
    { key: 'reports', label: 'Reports', icon: FileText },
    { key: 'audit-trail', label: 'Audit Trail', icon: Shield },
  ];

  const handleFilterChange = (filterType: keyof FilterState, value: string, checked: boolean) => {
    setFilters(prev => ({
      ...prev,
      [filterType]: checked 
        ? [...prev[filterType], value]
        : prev[filterType].filter(item => item !== value)
    }));
  };

  const clearAllFilters = () => {
    setFilters({
      clientType: [],
      touchpoint: [],
      caravan: [],
      municipality: [],
      market: [],
      product: [],
      pension: []
    });
  };

  const getClientTouchpoint = (client: ClientDetails) => {
    if (client.visits.length === 0) return 'N/A';
    const latestVisit = client.visits.reduce((latest, visit) => 
      new Date(visit.DateOfVisit) > new Date(latest.DateOfVisit) ? visit : latest
    );
    return `${latestVisit.Touchpoint}${getOrdinalSuffix(latestVisit.Touchpoint)}`;
  };

  const getOrdinalSuffix = (num: number) => {
    const j = num % 10;
    const k = num % 100;
    if (j === 1 && k !== 11) return "st";
    if (j === 2 && k !== 12) return "nd";
    if (j === 3 && k !== 13) return "rd";
    return "th";
  };

  const handleViewCaravanMember = (member: any) => {
    setSelectedCaravanMember(member);
    setIsCaravanModalOpen(true);
  };

  const handleCloseCaravanModal = () => {
    setIsCaravanModalOpen(false);
    setSelectedCaravanMember(null);
  };

  const getFullAddress = (client: ClientDetails) => {
    const defaultAddress = client.addresses.find(addr => addr.IsDefault) || client.addresses[0];
    if (!defaultAddress) return 'No address';
    return `${defaultAddress.Street}, ${defaultAddress.Municipality}, ${defaultAddress.Province}`;
  };

  const exportToCSV = () => {
    const csvHeaders = ['Client Name', 'TP', 'Municipality', 'Market', 'Product', 'Pension', 'Caravan'];
    const csvData = filteredClients.map(client => {
      const defaultAddress = client.addresses.find(addr => addr.IsDefault) || client.addresses[0];
      return [
        `"${client.FullName}"`,
        `"${getClientTouchpoint(client)}"`,
        `"${defaultAddress?.Municipality || 'N/A'}"`,
        `"${client.MarketType}"`,
        `"${client.ProductType}"`,
        `"${client.PensionType}"`,
        `"${client.caravan?.FullName || 'Unassigned'}"`
      ];
    });

    const csvContent = [csvHeaders.join(','), ...csvData.map(row => row.join(','))].join('\n');
    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
    const link = document.createElement('a');
    const url = URL.createObjectURL(blob);
    link.setAttribute('href', url);
    link.setAttribute('download', `clients-export-${new Date().toISOString().split('T')[0]}.csv`);
    link.style.visibility = 'hidden';
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  const getMarketBadgeColor = (market: string) => {
    switch (market) {
      case 'VIRGIN':
        return 'bg-green-100 text-green-800';
      case 'EXISTING':
        return 'bg-blue-100 text-blue-800';
      case 'VIRGIN-VISITED':
        return 'bg-yellow-100 text-yellow-800';
      case 'FULLYPAID':
        return 'bg-purple-100 text-purple-800';
      case 'OTHERS':
        return 'bg-gray-100 text-gray-800';
      default:
        return 'bg-gray-100 text-gray-800';
    }
  };

  const getAttendanceStatusColor = (status: string) => {
    switch (status) {
      case 'present':
        return 'bg-green-100 text-green-800';
      case 'late':
        return 'bg-yellow-100 text-yellow-800';
      case 'absent':
        return 'bg-red-100 text-red-800';
      default:
        return 'bg-gray-100 text-gray-800';
    }
  };

  const getSeverityColor = (severity: string) => {
    switch (severity) {
      case 'INFO':
        return 'bg-blue-100 text-blue-800';
      case 'WARNING':
        return 'bg-yellow-100 text-yellow-800';
      case 'ERROR':
        return 'bg-red-100 text-red-800';
      default:
        return 'bg-gray-100 text-gray-800';
    }
  };

  const COLORS = ['#0088FE', '#00C49F', '#FFBB28', '#FF8042', '#8884D8'];

  return (
    <div className="flex h-screen bg-gray-50">
      {/* Sidebar */}
      <div className="w-64 bg-white border-r border-gray-200 flex flex-col">
        {/* Logo */}
        <div className="flex items-center px-6 py-4 border-b border-gray-200">
          <div className="flex items-center space-x-3">
            <div className="w-8 h-8">
              <img src={logoImage} alt="IMU Logo" className="w-full h-full object-contain" />
            </div>
            <span className="text-lg font-semibold text-gray-900">IMU</span>
          </div>
        </div>

        {/* Navigation */}
        <nav className="flex-1 px-4 py-6 space-y-1">
          {sidebarItems.map((item) => {
            const Icon = item.icon;
            return (
              <button
                key={item.key}
                onClick={() => setActiveTab(item.key)}
                className={`w-full flex items-center space-x-3 px-3 py-2 rounded-lg text-left transition-colors ${
                  activeTab === item.key
                    ? 'bg-gray-900 text-white'
                    : 'text-gray-600 hover:bg-gray-100 hover:text-gray-900'
                }`}
              >
                <Icon className="w-5 h-5" />
                <span>{item.label}</span>
              </button>
            );
          })}
        </nav>
      </div>

      {/* Main Content */}
      <div className="flex-1 flex flex-col">
        {/* Header */}
        <div className="bg-white border-b border-gray-200 px-6 py-4">
          <div className="flex items-center justify-between">
            <h1 className="text-2xl font-semibold text-gray-900 capitalize">{activeTab}</h1>
            <div className="flex items-center space-x-4">
              {onLogout && (
                <Button variant="outline" onClick={onLogout} size="sm">
                  Logout
                </Button>
              )}
              <div className="w-8 h-8 bg-blue-600 rounded-full flex items-center justify-center">
                <span className="text-white text-sm font-medium">JD</span>
              </div>
            </div>
          </div>
        </div>

        {/* Content Area */}
        {activeTab === 'clients' ? (
          <div className="flex-1 overflow-auto p-6">
            {/* Search and Filter Bar */}
            <div className="flex items-center space-x-4 mb-6">
              {/* Search */}
              <div className="max-w-xs relative">
                <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-4 h-4" />
                <Input
                  placeholder="Search Clients"
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  className="pl-10"
                />
              </div>

              {/* Filter Dropdown */}
              <DropdownMenu>
                <DropdownMenuTrigger asChild>
                  <Button variant="outline" className="flex items-center space-x-2">
                    <Filter className="w-4 h-4" />
                    {Object.values(filters).some(arr => arr.length > 0) && (
                      <Badge className="ml-1 h-5 w-5 rounded-full p-0 flex items-center justify-center text-xs">
                        {Object.values(filters).reduce((total, arr) => total + arr.length, 0)}
                      </Badge>
                    )}
                  </Button>
                </DropdownMenuTrigger>
                <DropdownMenuContent className="w-80 max-h-96 overflow-y-auto">
                  <div className="flex items-center justify-between p-2">
                    <DropdownMenuLabel>Filters</DropdownMenuLabel>
                    <Button variant="ghost" size="sm" onClick={clearAllFilters}>
                      Clear All
                    </Button>
                  </div>
                  <DropdownMenuSeparator />

                  {/* Client Type */}
                  <div className="p-2">
                    <DropdownMenuLabel className="text-xs text-gray-500 uppercase tracking-wide">
                      Client Type
                    </DropdownMenuLabel>
                    {filterOptions.clientTypes.map((type) => (
                      <DropdownMenuCheckboxItem
                        key={type}
                        checked={filters.clientType.includes(type)}
                        onCheckedChange={(checked) => handleFilterChange('clientType', type, checked)}
                      >
                        {type}
                      </DropdownMenuCheckboxItem>
                    ))}
                  </div>
                  <DropdownMenuSeparator />

                  {/* Touchpoint */}
                  <div className="p-2">
                    <DropdownMenuLabel className="text-xs text-gray-500 uppercase tracking-wide">
                      Touchpoint
                    </DropdownMenuLabel>
                    {filterOptions.touchpoints.map((tp) => (
                      <DropdownMenuCheckboxItem
                        key={tp}
                        checked={filters.touchpoint.includes(tp)}
                        onCheckedChange={(checked) => handleFilterChange('touchpoint', tp, checked)}
                      >
                        {tp}{getOrdinalSuffix(parseInt(tp))}
                      </DropdownMenuCheckboxItem>
                    ))}
                  </div>
                  <DropdownMenuSeparator />

                  {/* Caravan */}
                  <div className="p-2">
                    <DropdownMenuLabel className="text-xs text-gray-500 uppercase tracking-wide">
                      Caravan
                    </DropdownMenuLabel>
                    {filterOptions.caravans.map((caravan) => (
                      <DropdownMenuCheckboxItem
                        key={caravan}
                        checked={filters.caravan.includes(caravan)}
                        onCheckedChange={(checked) => handleFilterChange('caravan', caravan, checked)}
                      >
                        {caravan}
                      </DropdownMenuCheckboxItem>
                    ))}
                  </div>
                  <DropdownMenuSeparator />

                  {/* Municipality */}
                  <div className="p-2">
                    <DropdownMenuLabel className="text-xs text-gray-500 uppercase tracking-wide">
                      Municipality
                    </DropdownMenuLabel>
                    {filterOptions.municipalities.map((municipality) => (
                      <DropdownMenuCheckboxItem
                        key={municipality}
                        checked={filters.municipality.includes(municipality)}
                        onCheckedChange={(checked) => handleFilterChange('municipality', municipality, checked)}
                      >
                        {municipality}
                      </DropdownMenuCheckboxItem>
                    ))}
                  </div>
                  <DropdownMenuSeparator />

                  {/* Market */}
                  <div className="p-2">
                    <DropdownMenuLabel className="text-xs text-gray-500 uppercase tracking-wide">
                      Market
                    </DropdownMenuLabel>
                    {filterOptions.markets.map((market) => (
                      <DropdownMenuCheckboxItem
                        key={market}
                        checked={filters.market.includes(market)}
                        onCheckedChange={(checked) => handleFilterChange('market', market, checked)}
                      >
                        {market}
                      </DropdownMenuCheckboxItem>
                    ))}
                  </div>
                  <DropdownMenuSeparator />

                  {/* Product */}
                  <div className="p-2">
                    <DropdownMenuLabel className="text-xs text-gray-500 uppercase tracking-wide">
                      Product
                    </DropdownMenuLabel>
                    {filterOptions.products.map((product) => (
                      <DropdownMenuCheckboxItem
                        key={product}
                        checked={filters.product.includes(product)}
                        onCheckedChange={(checked) => handleFilterChange('product', product, checked)}
                      >
                        {product}
                      </DropdownMenuCheckboxItem>
                    ))}
                  </div>
                  <DropdownMenuSeparator />

                  {/* Pension */}
                  <div className="p-2">
                    <DropdownMenuLabel className="text-xs text-gray-500 uppercase tracking-wide">
                      Pension
                    </DropdownMenuLabel>
                    {filterOptions.pensions.map((pension) => (
                      <DropdownMenuCheckboxItem
                        key={pension}
                        checked={filters.pension.includes(pension)}
                        onCheckedChange={(checked) => handleFilterChange('pension', pension, checked)}
                      >
                        {pension}
                      </DropdownMenuCheckboxItem>
                    ))}
                  </div>
                </DropdownMenuContent>
              </DropdownMenu>

              {/* Add Client Button */}
              <Button className="flex items-center">
                <Plus className="w-4 h-4" />
              </Button>

              {/* Export Button */}
              <Button variant="outline" onClick={exportToCSV} className="flex items-center">
                <Download className="w-4 h-4" />
              </Button>
            </div>

            {/* Results Count */}
            <div className="mb-4">
              <p className="text-sm text-gray-600">
                Showing {filteredClients.length} of {allClients.length} clients
              </p>
            </div>

            {/* Clients Table */}
            <div className="bg-white rounded-lg border border-gray-200 overflow-hidden max-h-[600px] overflow-y-auto">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Client Name</TableHead>
                    <TableHead>TP</TableHead>
                    <TableHead>Municipality</TableHead>
                    <TableHead>Market</TableHead>
                    <TableHead>Product</TableHead>
                    <TableHead>Pension</TableHead>
                    <TableHead>Caravan</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {filteredClients.map((client) => {
                    const defaultAddress = client.addresses.find(addr => addr.IsDefault) || client.addresses[0];
                    return (
                      <TableRow key={client.ClientID} className="hover:bg-gray-50">
                        <TableCell className="font-medium">{client.FullName}</TableCell>
                        <TableCell>{getClientTouchpoint(client)}</TableCell>
                        <TableCell>{defaultAddress?.Municipality || 'N/A'}</TableCell>
                        <TableCell>
                          <Badge className={`${getMarketBadgeColor(client.MarketType)} border-0`}>
                            {client.MarketType}
                          </Badge>
                        </TableCell>
                        <TableCell>{client.ProductType}</TableCell>
                        <TableCell>{client.PensionType}</TableCell>
                        <TableCell>{client.caravan?.FullName || 'Unassigned'}</TableCell>
                      </TableRow>
                    );
                  })}
                </TableBody>
              </Table>
            </div>

            {/* Pagination */}
            <div className="flex items-center justify-between mt-6">
              <div className="text-sm text-gray-600">
                Showing 1 to {Math.min(filteredClients.length, 50)} of {filteredClients.length} results
              </div>
              <div className="flex items-center space-x-2">
                <Button variant="outline" size="sm" disabled>
                  Previous
                </Button>
                <Button variant="outline" size="sm" className="bg-gray-900 text-white">
                  1
                </Button>
                <Button variant="outline" size="sm">
                  2
                </Button>
                <Button variant="outline" size="sm">
                  3
                </Button>
                <span className="text-gray-400">...</span>
                <Button variant="outline" size="sm">
                  67
                </Button>
                <Button variant="outline" size="sm">
                  68
                </Button>
                <Button variant="outline" size="sm">
                  Next
                </Button>
              </div>
            </div>
          </div>
        ) : activeTab === 'caravan' ? (
          <div className="flex-1 overflow-auto p-6">
            {/* Caravan Table */}
            <div className="bg-white rounded-lg border border-gray-200 overflow-hidden max-h-[600px] overflow-y-auto">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead className="w-12">View</TableHead>
                    <TableHead>Username</TableHead>
                    <TableHead>Email</TableHead>
                    <TableHead>First Name</TableHead>
                    <TableHead>Last Name</TableHead>
                    <TableHead>Group</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {caravanTeams.map((member, index) => (
                    <TableRow key={index} className="hover:bg-gray-50">
                      <TableCell>
                        <Button 
                          variant="ghost" 
                          size="sm" 
                          className="p-2"
                          onClick={() => handleViewCaravanMember(member)}
                        >
                          <Eye className="w-4 h-4" />
                        </Button>
                      </TableCell>
                      <TableCell className="font-medium">{member.username}</TableCell>
                      <TableCell>{member.email}</TableCell>
                      <TableCell>{member.firstName}</TableCell>
                      <TableCell>{member.lastName}</TableCell>
                      <TableCell>
                        <Badge variant="outline" className="bg-blue-50 text-blue-700 border-blue-200">
                          {member.group}
                        </Badge>
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </div>

            {/* Results Count */}
            <div className="mt-4">
              <p className="text-sm text-gray-600">
                Showing {caravanTeams.length} caravan members across 6 teams
              </p>
            </div>
          </div>
        ) : activeTab === 'groups' ? (
          <div className="flex-1 overflow-auto p-6">
            <TooltipProvider>
              <Accordion type="multiple" className="space-y-4">
                {Object.entries(groupsData).map(([groupName, groupInfo]) => (
                  <AccordionItem key={groupName} value={groupName} className="bg-white rounded-lg border border-gray-200">
                    <AccordionTrigger className="px-6 py-4 hover:no-underline">
                      <div className="flex items-center justify-between w-full">
                        <div className="text-left">
                          <h3 className="font-semibold text-gray-900">{groupName}</h3>
                          <p className="text-sm text-gray-600 mt-1">{groupInfo.description}</p>
                        </div>
                        <Badge variant="outline" className="bg-gray-50 text-gray-700 border-gray-200 mr-4">
                          {groupInfo.teams.length} Teams
                        </Badge>
                      </div>
                    </AccordionTrigger>
                    <AccordionContent className="px-6 pb-4">
                      <div className="space-y-6">
                        {groupInfo.teams.map((teamName) => {
                          const teamMembers = getGroupTeamMembers(teamName);
                          return (
                            <div key={teamName} className="border rounded-lg overflow-hidden">
                              <div className="bg-gray-50 px-4 py-3 border-b">
                                <h4 className="font-medium text-gray-900">{teamName}</h4>
                                <p className="text-sm text-gray-600">{teamMembers.length} members</p>
                              </div>
                              <Table>
                                <TableHeader>
                                  <TableRow>
                                    <TableHead className="w-12">View</TableHead>
                                    <TableHead>Username</TableHead>
                                    <TableHead>Email</TableHead>
                                    <TableHead>First Name</TableHead>
                                    <TableHead>Last Name</TableHead>
                                    <TableHead>Position</TableHead>
                                    <TableHead className="w-32">Actions</TableHead>
                                  </TableRow>
                                </TableHeader>
                                <TableBody>
                                  {teamMembers.map((member, index) => (
                                    <TableRow key={`${teamName}-${index}`} className="hover:bg-gray-50">
                                      <TableCell>
                                        <Button variant="ghost" size="sm" className="p-2">
                                          <Eye className="w-4 h-4" />
                                        </Button>
                                      </TableCell>
                                      <TableCell className="font-medium">{member.username}</TableCell>
                                      <TableCell>{member.email}</TableCell>
                                      <TableCell>{member.firstName}</TableCell>
                                      <TableCell>{member.lastName}</TableCell>
                                      <TableCell>
                                        <Badge 
                                          variant="outline" 
                                          className={member.isLeader 
                                            ? "bg-yellow-50 text-yellow-700 border-yellow-200"
                                            : "bg-gray-50 text-gray-700 border-gray-200"
                                          }
                                        >
                                          {member.position}
                                        </Badge>
                                      </TableCell>
                                      <TableCell>
                                        <div className="flex items-center space-x-2">
                                          {!member.isLeader && (
                                            <Tooltip>
                                              <TooltipTrigger asChild>
                                                <Button variant="ghost" size="sm" className="p-2">
                                                  <Crown className="w-4 h-4 text-yellow-600" />
                                                </Button>
                                              </TooltipTrigger>
                                              <TooltipContent>
                                                <p>Set as Leader</p>
                                              </TooltipContent>
                                            </Tooltip>
                                          )}
                                          <Tooltip>
                                            <TooltipTrigger asChild>
                                              <Button variant="ghost" size="sm" className="p-2">
                                                <UserMinus className="w-4 h-4 text-red-600" />
                                              </Button>
                                            </TooltipTrigger>
                                            <TooltipContent>
                                              <p>Remove from group</p>
                                            </TooltipContent>
                                          </Tooltip>
                                        </div>
                                      </TableCell>
                                    </TableRow>
                                  ))}
                                </TableBody>
                              </Table>
                            </div>
                          );
                        })}
                      </div>
                    </AccordionContent>
                  </AccordionItem>
                ))}
              </Accordion>
            </TooltipProvider>
          </div>
        ) : activeTab === 'dashboard' ? (
          <div className="flex-1 overflow-auto p-6">
            {/* Dashboard Overview Cards */}
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
              <Card>
                <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                  <CardTitle className="text-sm font-medium">Total Clients</CardTitle>
                  <Users className="h-4 w-4 text-muted-foreground" />
                </CardHeader>
                <CardContent>
                  <div className="text-2xl font-bold">{dashboardData.totalClients.toLocaleString()}</div>
                  <p className="text-xs text-muted-foreground">
                    <TrendingUp className="inline h-3 w-3 mr-1" />
                    +12% from last month
                  </p>
                </CardContent>
              </Card>
              <Card>
                <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                  <CardTitle className="text-sm font-medium">Active Caravans</CardTitle>
                  <Car className="h-4 w-4 text-muted-foreground" />
                </CardHeader>
                <CardContent>
                  <div className="text-2xl font-bold">{dashboardData.activeCaravans}</div>
                  <p className="text-xs text-muted-foreground">
                    <TrendingUp className="inline h-3 w-3 mr-1" />
                    +2 new teams
                  </p>
                </CardContent>
              </Card>
              <Card>
                <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                  <CardTitle className="text-sm font-medium">Completed Visits</CardTitle>
                  <CheckCircle className="h-4 w-4 text-muted-foreground" />
                </CardHeader>
                <CardContent>
                  <div className="text-2xl font-bold">{dashboardData.completedVisits.toLocaleString()}</div>
                  <p className="text-xs text-muted-foreground">
                    <TrendingUp className="inline h-3 w-3 mr-1" />
                    +8.2% this week
                  </p>
                </CardContent>
              </Card>
              <Card>
                <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                  <CardTitle className="text-sm font-medium">Pending Approvals</CardTitle>
                  <Clock className="h-4 w-4 text-muted-foreground" />
                </CardHeader>
                <CardContent>
                  <div className="text-2xl font-bold">{dashboardData.pendingApprovals}</div>
                  <p className="text-xs text-muted-foreground">
                    <TrendingDown className="inline h-3 w-3 mr-1" />
                    -5 from yesterday
                  </p>
                </CardContent>
              </Card>
            </div>

            {/* Charts Section */}
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-8">
              {/* Market Distribution */}
              <Card>
                <CardHeader>
                  <CardTitle>Client Distribution by Market Type</CardTitle>
                  <CardDescription>Distribution of clients across different market segments</CardDescription>
                </CardHeader>
                <CardContent>
                  <ResponsiveContainer width="100%" height={300}>
                    <PieChart>
                      <Pie
                        data={dashboardData.marketData}
                        cx="50%"
                        cy="50%"
                        labelLine={false}
                        label={({ name, percent }) => `${name} ${(percent * 100).toFixed(0)}%`}
                        outerRadius={80}
                        fill="#8884d8"
                        dataKey="value"
                      >
                        {dashboardData.marketData.map((entry, index) => (
                          <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                        ))}
                      </Pie>
                    </PieChart>
                  </ResponsiveContainer>
                </CardContent>
              </Card>

              {/* Monthly Visits Trend */}
              <Card>
                <CardHeader>
                  <CardTitle>Monthly Visits & Client Trend</CardTitle>
                  <CardDescription>Visits and client acquisition over time</CardDescription>
                </CardHeader>
                <CardContent>
                  <ResponsiveContainer width="100%" height={300}>
                    <AreaChart data={dashboardData.monthlyVisits}>
                      <CartesianGrid strokeDasharray="3 3" />
                      <XAxis dataKey="month" />
                      <YAxis />
                      <Legend />
                      <Area type="monotone" dataKey="visits" stackId="1" stroke="#8884d8" fill="#8884d8" name="Visits" />
                      <Area type="monotone" dataKey="clients" stackId="1" stroke="#82ca9d" fill="#82ca9d" name="Clients" />
                    </AreaChart>
                  </ResponsiveContainer>
                </CardContent>
              </Card>
            </div>

            {/* Caravan Performance and Touchpoint Progress */}
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
              {/* Caravan Performance */}
              <Card>
                <CardHeader>
                  <CardTitle>Top Caravan Performance</CardTitle>
                  <CardDescription>Client assignments and visit completion rates</CardDescription>
                </CardHeader>
                <CardContent>
                  <ResponsiveContainer width="100%" height={300}>
                    <BarChart data={dashboardData.caravanPerformance}>
                      <CartesianGrid strokeDasharray="3 3" />
                      <XAxis dataKey="name" />
                      <YAxis />
                      <Legend />
                      <Bar dataKey="clients" fill="#8884d8" name="Clients" />
                      <Bar dataKey="visits" fill="#82ca9d" name="Visits" />
                    </BarChart>
                  </ResponsiveContainer>
                </CardContent>
              </Card>

              {/* Touchpoint Progress */}
              <Card>
                <CardHeader>
                  <CardTitle>Touchpoint Progress</CardTitle>
                  <CardDescription>Completion status across all touchpoints</CardDescription>
                </CardHeader>
                <CardContent>
                  <ResponsiveContainer width="100%" height={300}>
                    <BarChart data={dashboardData.touchpointData}>
                      <CartesianGrid strokeDasharray="3 3" />
                      <XAxis dataKey="touchpoint" />
                      <YAxis />
                      <Legend />
                      <Bar dataKey="completed" fill="#22c55e" name="Completed" />
                      <Bar dataKey="pending" fill="#f59e0b" name="Pending" />
                    </BarChart>
                  </ResponsiveContainer>
                </CardContent>
              </Card>
            </div>
          </div>
        ) : activeTab === 'attendance' ? (
          <div className="flex-1 overflow-auto p-6">
            {/* Attendance Overview */}
            <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-6">
              <Card>
                <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                  <CardTitle className="text-sm font-medium">Present Today</CardTitle>
                  <CheckCircle className="h-4 w-4 text-green-600" />
                </CardHeader>
                <CardContent>
                  <div className="text-2xl font-bold text-green-600">
                    {attendanceData.filter(member => member.attendance[6]?.status === 'present').length}
                  </div>
                  <p className="text-xs text-muted-foreground">
                    out of {attendanceData.length} members
                  </p>
                </CardContent>
              </Card>
              <Card>
                <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                  <CardTitle className="text-sm font-medium">Late Today</CardTitle>
                  <Clock className="h-4 w-4 text-yellow-600" />
                </CardHeader>
                <CardContent>
                  <div className="text-2xl font-bold text-yellow-600">
                    {attendanceData.filter(member => member.attendance[6]?.status === 'late').length}
                  </div>
                  <p className="text-xs text-muted-foreground">
                    late arrivals
                  </p>
                </CardContent>
              </Card>
              <Card>
                <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                  <CardTitle className="text-sm font-medium">Absent Today</CardTitle>
                  <XCircle className="h-4 w-4 text-red-600" />
                </CardHeader>
                <CardContent>
                  <div className="text-2xl font-bold text-red-600">
                    {attendanceData.filter(member => member.attendance[6]?.status === 'absent').length}
                  </div>
                  <p className="text-xs text-muted-foreground">
                    absent members
                  </p>
                </CardContent>
              </Card>
            </div>

            {/* Attendance Table */}
            <Card>
              <CardHeader>
                <CardTitle>Weekly Attendance</CardTitle>
                <CardDescription>Attendance tracking for all caravan members</CardDescription>
              </CardHeader>
              <CardContent>
                <div className="overflow-x-auto max-h-[600px] overflow-y-auto">
                  <Table>
                    <TableHeader>
                      <TableRow>
                        <TableHead className="min-w-[200px]">Member</TableHead>
                        <TableHead>Team</TableHead>
                        {attendanceData[0]?.attendance.map((day, index) => (
                          <TableHead key={index} className="text-center min-w-[100px]">
                            {day.date}
                          </TableHead>
                        ))}
                      </TableRow>
                    </TableHeader>
                    <TableBody>
                      {attendanceData.map((member, memberIndex) => (
                        <TableRow key={memberIndex} className="hover:bg-gray-50">
                          <TableCell>
                            <div>
                              <div className="font-medium">{member.firstName} {member.lastName}</div>
                              <div className="text-sm text-gray-500">{member.username}</div>
                            </div>
                          </TableCell>
                          <TableCell>
                            <Badge variant="outline" className="bg-blue-50 text-blue-700 border-blue-200">
                              {member.group.split(' ').slice(0, 2).join(' ')}
                            </Badge>
                          </TableCell>
                          {member.attendance.map((day, dayIndex) => (
                            <TableCell key={dayIndex} className="text-center">
                              <div className="space-y-1">
                                <Badge className={`${getAttendanceStatusColor(day.status)} border-0 text-xs`}>
                                  {day.status}
                                </Badge>
                                {day.timeIn && (
                                  <div className="text-xs text-gray-500">
                                    In: {day.timeIn}
                                  </div>
                                )}
                                {day.timeOut && (
                                  <div className="text-xs text-gray-500">
                                    Out: {day.timeOut}
                                  </div>
                                )}
                              </div>
                            </TableCell>
                          ))}
                        </TableRow>
                      ))}
                    </TableBody>
                  </Table>
                </div>
              </CardContent>
            </Card>
          </div>
        ) : activeTab === 'users' ? (
          <div className="flex-1 overflow-auto p-6">
            {/* User Management Header */}
            <div className="flex items-center justify-between mb-6">
              <div>
                <h2 className="text-2xl font-semibold text-gray-900">User Management</h2>
                <p className="text-gray-600">Manage system users and their permissions</p>
              </div>
              <Button className="flex items-center space-x-2">
                <UserPlus className="w-4 h-4" />
                <span>Add User</span>
              </Button>
            </div>

            {/* User Statistics */}
            <div className="grid grid-cols-1 md:grid-cols-4 gap-6 mb-6">
              <Card>
                <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                  <CardTitle className="text-sm font-medium">Total Users</CardTitle>
                  <Users className="h-4 w-4 text-muted-foreground" />
                </CardHeader>
                <CardContent>
                  <div className="text-2xl font-bold">{caravanTeams.length}</div>
                  <p className="text-xs text-muted-foreground">Active accounts</p>
                </CardContent>
              </Card>
              <Card>
                <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                  <CardTitle className="text-sm font-medium">Admins</CardTitle>
                  <Shield className="h-4 w-4 text-muted-foreground" />
                </CardHeader>
                <CardContent>
                  <div className="text-2xl font-bold">3</div>
                  <p className="text-xs text-muted-foreground">Administrator roles</p>
                </CardContent>
              </Card>
              <Card>
                <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                  <CardTitle className="text-sm font-medium">Field Users</CardTitle>
                  <MapPin className="h-4 w-4 text-muted-foreground" />
                </CardHeader>
                <CardContent>
                  <div className="text-2xl font-bold">{caravanTeams.length - 3}</div>
                  <p className="text-xs text-muted-foreground">Field agents</p>
                </CardContent>
              </Card>
              <Card>
                <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                  <CardTitle className="text-sm font-medium">Online Now</CardTitle>
                  <Activity className="h-4 w-4 text-green-600" />
                </CardHeader>
                <CardContent>
                  <div className="text-2xl font-bold text-green-600">
                    {Math.floor(caravanTeams.length * 0.6)}
                  </div>
                  <p className="text-xs text-muted-foreground">Currently active</p>
                </CardContent>
              </Card>
            </div>

            {/* Users Table */}
            <Card>
              <CardHeader>
                <CardTitle>System Users</CardTitle>
                <CardDescription>Manage user accounts and permissions</CardDescription>
              </CardHeader>
              <CardContent>
                <div className="overflow-hidden max-h-[600px] overflow-y-auto">
                  <Table>
                    <TableHeader>
                      <TableRow>
                        <TableHead>User</TableHead>
                        <TableHead>Email</TableHead>
                        <TableHead>Role</TableHead>
                        <TableHead>Team</TableHead>
                        <TableHead>Status</TableHead>
                        <TableHead>Last Login</TableHead>
                        <TableHead className="w-32">Actions</TableHead>
                      </TableRow>
                    </TableHeader>
                    <TableBody>
                      {caravanTeams.map((user, index) => {
                        const isAdmin = index < 3;
                        const isOnline = Math.random() > 0.4;
                        const lastLogin = new Date();
                        lastLogin.setHours(lastLogin.getHours() - Math.floor(Math.random() * 48));
                        
                        return (
                          <TableRow key={index} className="hover:bg-gray-50">
                            <TableCell>
                              <div className="flex items-center space-x-3">
                                <div className="w-8 h-8 bg-gray-200 rounded-full flex items-center justify-center">
                                  <span className="text-sm font-medium">
                                    {user.firstName.charAt(0)}{user.lastName.charAt(0)}
                                  </span>
                                </div>
                                <div>
                                  <div className="font-medium">{user.firstName} {user.lastName}</div>
                                  <div className="text-sm text-gray-500">@{user.username}</div>
                                </div>
                              </div>
                            </TableCell>
                            <TableCell>{user.email}</TableCell>
                            <TableCell>
                              <Badge 
                                variant="outline" 
                                className={isAdmin 
                                  ? "bg-purple-50 text-purple-700 border-purple-200" 
                                  : "bg-blue-50 text-blue-700 border-blue-200"
                                }
                              >
                                {isAdmin ? 'Administrator' : 'Field Agent'}
                              </Badge>
                            </TableCell>
                            <TableCell>
                              <Badge variant="outline" className="bg-gray-50 text-gray-700 border-gray-200">
                                {user.group.split(' ').slice(0, 2).join(' ')}
                              </Badge>
                            </TableCell>
                            <TableCell>
                              <div className="flex items-center space-x-2">
                                <div className={`w-2 h-2 rounded-full ${isOnline ? 'bg-green-500' : 'bg-gray-300'}`} />
                                <span className="text-sm">{isOnline ? 'Online' : 'Offline'}</span>
                              </div>
                            </TableCell>
                            <TableCell className="text-sm text-gray-500">
                              {lastLogin.toLocaleDateString('en-US', { 
                                month: 'short', 
                                day: 'numeric',
                                hour: '2-digit',
                                minute: '2-digit'
                              })}
                            </TableCell>
                            <TableCell>
                              <div className="flex items-center space-x-1">
                                <Button variant="ghost" size="sm" className="p-2">
                                  <Edit className="w-4 h-4" />
                                </Button>
                                <Button variant="ghost" size="sm" className="p-2">
                                  <Settings className="w-4 h-4" />
                                </Button>
                                {!isAdmin && (
                                  <Button variant="ghost" size="sm" className="p-2 text-red-600">
                                    <Trash2 className="w-4 h-4" />
                                  </Button>
                                )}
                              </div>
                            </TableCell>
                          </TableRow>
                        );
                      })}
                    </TableBody>
                  </Table>
                </div>
              </CardContent>
            </Card>
          </div>
        ) : activeTab === 'audit-trail' ? (
          <div className="flex-1 overflow-auto p-6">
            {/* Audit Trail Header */}
            <div className="flex items-center justify-between mb-6">
              <div>
                <h2 className="text-2xl font-semibold text-gray-900">Audit Trail</h2>
                <p className="text-gray-600">System activity and security monitoring</p>
              </div>
              <div className="flex items-center space-x-4">
                <Select defaultValue="all">
                  <SelectTrigger className="w-40">
                    <SelectValue placeholder="Filter by module" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="all">All Modules</SelectItem>
                    <SelectItem value="auth">Authentication</SelectItem>
                    <SelectItem value="client">Client Management</SelectItem>
                    <SelectItem value="visit">Visit Management</SelectItem>
                    <SelectItem value="approval">Approval System</SelectItem>
                    <SelectItem value="system">System</SelectItem>
                  </SelectContent>
                </Select>
                <Button variant="outline">
                  <Download className="w-4 h-4 mr-2" />
                  Export
                </Button>
              </div>
            </div>

            {/* Activity Summary */}
            <div className="grid grid-cols-1 md:grid-cols-4 gap-6 mb-6">
              <Card>
                <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                  <CardTitle className="text-sm font-medium">Total Events</CardTitle>
                  <Activity className="h-4 w-4 text-muted-foreground" />
                </CardHeader>
                <CardContent>
                  <div className="text-2xl font-bold">{auditTrailData.length}</div>
                  <p className="text-xs text-muted-foreground">Last 24 hours</p>
                </CardContent>
              </Card>
              <Card>
                <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                  <CardTitle className="text-sm font-medium">Info Events</CardTitle>
                  <Info className="h-4 w-4 text-blue-600" />
                </CardHeader>
                <CardContent>
                  <div className="text-2xl font-bold text-blue-600">
                    {auditTrailData.filter(log => log.severity === 'INFO').length}
                  </div>
                  <p className="text-xs text-muted-foreground">Normal operations</p>
                </CardContent>
              </Card>
              <Card>
                <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                  <CardTitle className="text-sm font-medium">Warnings</CardTitle>
                  <AlertTriangle className="h-4 w-4 text-yellow-600" />
                </CardHeader>
                <CardContent>
                  <div className="text-2xl font-bold text-yellow-600">
                    {auditTrailData.filter(log => log.severity === 'WARNING').length}
                  </div>
                  <p className="text-xs text-muted-foreground">Require attention</p>
                </CardContent>
              </Card>
              <Card>
                <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                  <CardTitle className="text-sm font-medium">Errors</CardTitle>
                  <XCircle className="h-4 w-4 text-red-600" />
                </CardHeader>
                <CardContent>
                  <div className="text-2xl font-bold text-red-600">
                    {auditTrailData.filter(log => log.severity === 'ERROR').length}
                  </div>
                  <p className="text-xs text-muted-foreground">Critical issues</p>
                </CardContent>
              </Card>
            </div>

            {/* Audit Trail Table */}
            <Card>
              <CardHeader>
                <CardTitle>Recent Activity</CardTitle>
                <CardDescription>Detailed system event log with user actions and system processes</CardDescription>
              </CardHeader>
              <CardContent>
                <div className="overflow-hidden max-h-[600px] overflow-y-auto">
                  <Table>
                    <TableHeader>
                      <TableRow>
                        <TableHead>Timestamp</TableHead>
                        <TableHead>Event ID</TableHead>
                        <TableHead>Action</TableHead>
                        <TableHead>Description</TableHead>
                        <TableHead>User</TableHead>
                        <TableHead>Module</TableHead>
                        <TableHead>IP Address</TableHead>
                        <TableHead>Severity</TableHead>
                      </TableRow>
                    </TableHeader>
                    <TableBody>
                      {auditTrailData.map((log) => (
                        <TableRow key={log.id} className="hover:bg-gray-50">
                          <TableCell className="text-sm">
                            {new Date(log.timestamp).toLocaleString('en-US', {
                              month: 'short',
                              day: 'numeric',
                              hour: '2-digit',
                              minute: '2-digit',
                              second: '2-digit'
                            })}
                          </TableCell>
                          <TableCell className="font-mono text-sm">{log.id}</TableCell>
                          <TableCell className="font-medium">{log.action}</TableCell>
                          <TableCell>{log.description}</TableCell>
                          <TableCell>{log.user}</TableCell>
                          <TableCell>
                            <Badge variant="outline" className="bg-gray-50 text-gray-700 border-gray-200">
                              {log.module}
                            </Badge>
                          </TableCell>
                          <TableCell className="font-mono text-sm">{log.ipAddress}</TableCell>
                          <TableCell>
                            <Badge className={`${getSeverityColor(log.severity)} border-0`}>
                              {log.severity}
                            </Badge>
                          </TableCell>
                        </TableRow>
                      ))}
                    </TableBody>
                  </Table>
                </div>
              </CardContent>
            </Card>
          </div>
        ) : (
          // Placeholder for other tabs
          <div className="flex-1 flex items-center justify-center">
            <div className="text-center">
              <h2 className="text-2xl font-semibold text-gray-900 mb-2 capitalize">{activeTab}</h2>
              <p className="text-gray-600">This section is under development</p>
            </div>
          </div>
        )}
      </div>

      {/* Caravan Detail Modal */}
      <CaravanDetailModal
        isOpen={isCaravanModalOpen}
        onClose={handleCloseCaravanModal}
        member={selectedCaravanMember}
      />
    </div>
  );
}