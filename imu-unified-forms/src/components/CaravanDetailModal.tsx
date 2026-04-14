import { useState } from "react";
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle } from "./ui/dialog";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "./ui/tabs";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "./ui/table";
import { Badge } from "./ui/badge";
import { Button } from "./ui/button";
import React from "react";
import { DataService } from "../services/DataService";

interface CaravanMember {
  firstName: string;
  lastName: string;
  username: string;
  email: string;
  group: string;
}

interface CaravanDetailModalProps {
  isOpen: boolean;
  onClose: () => void;
  member: CaravanMember | null;
}

export function CaravanDetailModal({ isOpen, onClose, member }: CaravanDetailModalProps) {
  const [activeTab, setActiveTab] = useState('details');

  if (!member) return null;

  // Get data for this caravan member
  const allClients = DataService.getAllClientDetails();
  const caravanClients = allClients.filter(client => 
    client.caravan?.FullName.toLowerCase().includes(member.lastName.toLowerCase()) ||
    client.caravan?.FullName.toLowerCase().includes(member.firstName.toLowerCase())
  );

  // Get all visits for this caravan's clients
  const caravanVisits = caravanClients.flatMap(client => 
    client.visits.map(visit => ({
      ...visit,
      clientName: client.FullName,
      clientPAN: client.PAN
    }))
  );

  // Get unique municipalities from client addresses
  const municipalities = [...new Set(
    caravanClients.flatMap(client => 
      client.addresses.map(addr => addr.Municipality)
    )
  )];

  const getOrdinalSuffix = (num: number) => {
    const j = num % 10;
    const k = num % 100;
    if (j === 1 && k !== 11) return "st";
    if (j === 2 && k !== 12) return "nd";
    if (j === 3 && k !== 13) return "rd";
    return "th";
  };

  return (
    <Dialog open={isOpen} onOpenChange={onClose}>
      <DialogContent className="!max-w-none !w-[74vw] !h-[90vh] flex flex-col p-0">
        <DialogHeader className="flex-shrink-0 p-6 pb-4 border-b border-gray-200">
          <DialogTitle className="flex items-center space-x-3">
            <div className="w-10 h-10 bg-gray-800 rounded-full flex items-center justify-center">
              <span className="text-white font-medium">
                {member.firstName.charAt(0)}{member.lastName.charAt(0)}
              </span>
            </div>
            <div>
              <h2 className="text-xl font-semibold text-gray-900">{member.firstName} {member.lastName}</h2>
              <p className="text-sm text-gray-500">{member.group}</p>
            </div>
          </DialogTitle>
          <DialogDescription className="text-gray-600">
            View detailed information about {member.firstName} {member.lastName}, including their assigned clients, visit history, and coverage areas.
          </DialogDescription>
        </DialogHeader>

        <Tabs value={activeTab} onValueChange={setActiveTab} className="flex-1 flex flex-col overflow-hidden px-6 pb-6">
          <TabsList className="grid w-full grid-cols-5 bg-gray-50 mb-4 flex-shrink-0">
            <TabsTrigger value="details" className="data-[state=active]:bg-white data-[state=active]:text-gray-900">
              Details
            </TabsTrigger>
            <TabsTrigger value="clients" className="data-[state=active]:bg-white data-[state=active]:text-gray-900">
              Clients ({caravanClients.length})
            </TabsTrigger>
            <TabsTrigger value="visits" className="data-[state=active]:bg-white data-[state=active]:text-gray-900">
              Visits ({caravanVisits.length})
            </TabsTrigger>
            <TabsTrigger value="itineraries" className="data-[state=active]:bg-white data-[state=active]:text-gray-900">
              Itineraries
            </TabsTrigger>
            <TabsTrigger value="municipalities" className="data-[state=active]:bg-white data-[state=active]:text-gray-900">
              Municipalities ({municipalities.length})
            </TabsTrigger>
          </TabsList>

          <div className="flex-1 overflow-hidden">
            <TabsContent value="details" className="flex-1 overflow-auto">
              <div className="bg-gray-50 rounded-lg border border-gray-200 p-6 h-full">
                <div className="grid grid-cols-2 gap-8 h-full">
                  <div className="bg-white rounded-lg p-6 border border-gray-100">
                    <h3 className="font-semibold text-gray-900 mb-6">Personal Information</h3>
                    <div className="space-y-4">
                      <div>
                        <label className="text-sm font-medium text-gray-500 block mb-1">Full Name</label>
                        <p className="text-gray-900 font-medium">{member.firstName} {member.lastName}</p>
                      </div>
                      <div>
                        <label className="text-sm font-medium text-gray-500 block mb-1">Username</label>
                        <p className="text-gray-700">{member.username}</p>
                      </div>
                      <div>
                        <label className="text-sm font-medium text-gray-500 block mb-1">Email</label>
                        <p className="text-gray-700">{member.email}</p>
                      </div>
                      <div>
                        <label className="text-sm font-medium text-gray-500 block mb-1">Team</label>
                        <Badge variant="outline" className="bg-gray-100 text-gray-700 border-gray-300">
                          {member.group}
                        </Badge>
                      </div>
                    </div>
                  </div>
                  <div className="bg-white rounded-lg p-6 border border-gray-100">
                    <h3 className="font-semibold text-gray-900 mb-6">Performance Summary</h3>
                    <div className="space-y-4">
                      <div className="flex justify-between items-center py-2 border-b border-gray-100">
                        <span className="text-sm font-medium text-gray-500">Total Clients</span>
                        <span className="font-semibold text-gray-800 text-lg">{caravanClients.length}</span>
                      </div>
                      <div className="flex justify-between items-center py-2 border-b border-gray-100">
                        <span className="text-sm font-medium text-gray-500">Total Visits</span>
                        <span className="font-semibold text-gray-800 text-lg">{caravanVisits.length}</span>
                      </div>
                      <div className="flex justify-between items-center py-2 border-b border-gray-100">
                        <span className="text-sm font-medium text-gray-500">Coverage Areas</span>
                        <span className="font-semibold text-gray-800 text-lg">{municipalities.length}</span>
                      </div>
                      <div className="flex justify-between items-center py-2">
                        <span className="text-sm font-medium text-gray-500">Average Visits/Client</span>
                        <span className="font-semibold text-gray-800 text-lg">
                          {caravanClients.length > 0 ? (caravanVisits.length / caravanClients.length).toFixed(1) : '0'}
                        </span>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </TabsContent>

            <TabsContent value="clients" className="flex-1 overflow-hidden">
              <div className="bg-white rounded-lg border border-gray-200 overflow-hidden h-full flex flex-col">
                <div className="bg-gray-50 px-4 py-3 border-b border-gray-200">
                  <h3 className="font-medium text-gray-900">Client Portfolio</h3>
                  <p className="text-sm text-gray-500">{caravanClients.length} total clients assigned</p>
                </div>
                <div className="flex-1 overflow-auto">
                  <Table>
                    <TableHeader className="sticky top-0 bg-white">
                      <TableRow>
                        <TableHead className="font-medium text-gray-700">Client Name</TableHead>
                        <TableHead className="font-medium text-gray-700">PAN</TableHead>
                        <TableHead className="font-medium text-gray-700">Municipality</TableHead>
                        <TableHead className="font-medium text-gray-700">Market Type</TableHead>
                        <TableHead className="font-medium text-gray-700">Product</TableHead>
                        <TableHead className="font-medium text-gray-700">Visits</TableHead>
                      </TableRow>
                    </TableHeader>
                    <TableBody>
                      {caravanClients.map((client) => {
                        const defaultAddress = client.addresses.find(addr => addr.IsDefault) || client.addresses[0];
                        return (
                          <TableRow key={client.ClientID} className="hover:bg-gray-50">
                            <TableCell className="font-medium text-gray-900">{client.FullName}</TableCell>
                            <TableCell className="text-gray-600">{client.PAN}</TableCell>
                            <TableCell className="text-gray-600">{defaultAddress?.Municipality || 'N/A'}</TableCell>
                            <TableCell>
                              <Badge variant="outline" className="bg-gray-100 text-gray-700 border-gray-300">
                                {client.MarketType}
                              </Badge>
                            </TableCell>
                            <TableCell className="text-gray-600">{client.ProductType}</TableCell>
                            <TableCell className="font-medium text-gray-800">{client.visits.length}</TableCell>
                          </TableRow>
                        );
                      })}
                    </TableBody>
                  </Table>
                </div>
              </div>
            </TabsContent>

            <TabsContent value="visits" className="flex-1 overflow-hidden">
              <div className="bg-white rounded-lg border border-gray-200 overflow-hidden h-full flex flex-col">
                <div className="bg-gray-50 px-4 py-3 border-b border-gray-200">
                  <h3 className="font-medium text-gray-900">Visit History</h3>
                  <p className="text-sm text-gray-500">{caravanVisits.length} total visits recorded</p>
                </div>
                <div className="flex-1 overflow-auto">
                  <Table>
                    <TableHeader className="sticky top-0 bg-white">
                      <TableRow>
                        <TableHead className="font-medium text-gray-700">Date</TableHead>
                        <TableHead className="font-medium text-gray-700">Client</TableHead>
                        <TableHead className="font-medium text-gray-700">Touchpoint</TableHead>
                        <TableHead className="font-medium text-gray-700">Type</TableHead>
                        <TableHead className="font-medium text-gray-700">Status</TableHead>
                      </TableRow>
                    </TableHeader>
                    <TableBody>
                      {caravanVisits
                        .sort((a, b) => new Date(b.DateOfVisit).getTime() - new Date(a.DateOfVisit).getTime())
                        .map((visit, index) => (
                          <TableRow key={index} className="hover:bg-gray-50">
                            <TableCell className="text-gray-600">{new Date(visit.DateOfVisit).toLocaleDateString()}</TableCell>
                            <TableCell className="font-medium text-gray-900">{visit.clientName}</TableCell>
                            <TableCell>
                              <Badge variant="outline" className="bg-gray-100 text-gray-700 border-gray-300">
                                {visit.Touchpoint}{getOrdinalSuffix(visit.Touchpoint)}
                              </Badge>
                            </TableCell>
                            <TableCell className="text-gray-600">{visit.VisitType}</TableCell>
                            <TableCell>
                              <Badge variant="outline" className={visit.IsCompleted ? "bg-gray-100 text-gray-700 border-gray-300" : "bg-gray-200 text-gray-600 border-gray-400"}>
                                {visit.IsCompleted ? 'Completed' : 'Pending'}
                              </Badge>
                            </TableCell>
                          </TableRow>
                        ))}
                    </TableBody>
                  </Table>
                </div>
              </div>
            </TabsContent>

            <TabsContent value="itineraries" className="flex-1 overflow-hidden">
              <div className="bg-white rounded-lg border border-gray-200 overflow-hidden h-full flex flex-col">
                <div className="bg-gray-50 px-4 py-3 border-b border-gray-200">
                  <h3 className="font-medium text-gray-900">Itinerary Management</h3>
                  <p className="text-sm text-gray-500">Planned visits and route optimization</p>
                </div>
                <div className="flex-1 overflow-auto p-6">
                  <div className="space-y-6">
                    {/* Weekly Itinerary Summary */}
                    <div className="grid grid-cols-3 gap-4">
                      <div className="bg-gray-50 rounded-lg p-4 text-center">
                        <h4 className="font-medium text-gray-900">This Week</h4>
                        <p className="text-2xl font-semibold text-gray-800 mt-2">
                          {Math.floor(caravanVisits.length * 0.3)}
                        </p>
                        <p className="text-sm text-gray-600">Planned Visits</p>
                      </div>
                      <div className="bg-gray-50 rounded-lg p-4 text-center">
                        <h4 className="font-medium text-gray-900">Next Week</h4>
                        <p className="text-2xl font-semibold text-gray-800 mt-2">
                          {Math.floor(caravanVisits.length * 0.25)}
                        </p>
                        <p className="text-sm text-gray-600">Scheduled Visits</p>
                      </div>
                      <div className="bg-gray-50 rounded-lg p-4 text-center">
                        <h4 className="font-medium text-gray-900">Pending</h4>
                        <p className="text-2xl font-semibold text-gray-800 mt-2">
                          {Math.floor(caravanVisits.length * 0.15)}
                        </p>
                        <p className="text-sm text-gray-600">To Schedule</p>
                      </div>
                    </div>

                    {/* Route Optimization */}
                    <div className="bg-gray-50 rounded-lg p-6">
                      <h4 className="font-medium text-gray-900 mb-4">Route Optimization</h4>
                      <div className="space-y-3">
                        <div className="flex justify-between items-center">
                          <span className="text-sm text-gray-600">Average Daily Travel</span>
                          <span className="font-medium text-gray-800">45 km</span>
                        </div>
                        <div className="flex justify-between items-center">
                          <span className="text-sm text-gray-600">Visits per Day</span>
                          <span className="font-medium text-gray-800">
                            {caravanVisits.length > 0 ? Math.ceil(caravanVisits.length / 30) : 0}
                          </span>
                        </div>
                        <div className="flex justify-between items-center">
                          <span className="text-sm text-gray-600">Route Efficiency</span>
                          <span className="font-medium text-gray-800">87%</span>
                        </div>
                      </div>
                    </div>

                    {/* Upcoming Itineraries */}
                    <div>
                      <h4 className="font-medium text-gray-900 mb-4">Upcoming Itineraries</h4>
                      <div className="space-y-3">
                        {municipalities.slice(0, 5).map((municipality, index) => {
                          const municipalityClients = caravanClients.filter(client =>
                            client.addresses.some(addr => addr.Municipality === municipality)
                          );
                          const nextVisitDate = new Date();
                          nextVisitDate.setDate(nextVisitDate.getDate() + (index + 1) * 2);
                          
                          return (
                            <div key={municipality} className="flex justify-between items-center p-3 bg-white rounded-lg border border-gray-200">
                              <div>
                                <p className="font-medium text-gray-900">{municipality}</p>
                                <p className="text-sm text-gray-600">{municipalityClients.length} clients scheduled</p>
                              </div>
                              <div className="text-right">
                                <p className="text-sm font-medium text-gray-800">
                                  {nextVisitDate.toLocaleDateString()}
                                </p>
                                <p className="text-xs text-gray-500">
                                  {index === 0 ? 'Tomorrow' : `${(index + 1) * 2} days`}
                                </p>
                              </div>
                            </div>
                          );
                        })}
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </TabsContent>

            <TabsContent value="municipalities" className="flex-1 overflow-hidden">
              <div className="bg-white rounded-lg border border-gray-200 overflow-hidden h-full flex flex-col">
                <div className="bg-gray-50 px-4 py-3 border-b border-gray-200">
                  <h3 className="font-medium text-gray-900">Coverage Areas</h3>
                  <p className="text-sm text-gray-500">{municipalities.length} municipalities covered</p>
                </div>
                <div className="flex-1 overflow-auto">
                  <Table>
                    <TableHeader className="sticky top-0 bg-white">
                      <TableRow>
                        <TableHead className="font-medium text-gray-700">Municipality</TableHead>
                        <TableHead className="font-medium text-gray-700">Clients</TableHead>
                        <TableHead className="font-medium text-gray-700">Visits</TableHead>
                      </TableRow>
                    </TableHeader>
                    <TableBody>
                      {municipalities.map((municipality) => {
                        const municipalityClients = caravanClients.filter(client =>
                          client.addresses.some(addr => addr.Municipality === municipality)
                        );
                        const municipalityVisits = municipalityClients.reduce((total, client) => total + client.visits.length, 0);
                        
                        return (
                          <TableRow key={municipality} className="hover:bg-gray-50">
                            <TableCell className="font-medium text-gray-900">{municipality}</TableCell>
                            <TableCell className="font-medium text-gray-800">{municipalityClients.length}</TableCell>
                            <TableCell className="font-medium text-gray-800">{municipalityVisits}</TableCell>
                          </TableRow>
                        );
                      })}
                    </TableBody>
                  </Table>
                </div>
              </div>
            </TabsContent>
          </div>
        </Tabs>
      </DialogContent>
    </Dialog>
  );
}