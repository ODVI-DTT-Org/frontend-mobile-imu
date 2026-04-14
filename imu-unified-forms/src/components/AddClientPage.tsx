import { useState } from "react";
import { ArrowLeft } from "lucide-react";
import { Button } from "./ui/button";
import { Input } from "./ui/input";
import { Label } from "./ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "./ui/select";
import { MobileStatusBar } from "./MobileStatusBar";
import { DataService } from "../services/DataService";
import { toast } from "sonner@2.0.3";

interface AddClientPageProps {
  onBack: () => void;
  onClientAdded?: () => void;
}

export function AddClientPage({ onBack, onClientAdded }: AddClientPageProps) {
  const [formData, setFormData] = useState({
    fullName: "",
    productType: "",
    marketType: "",
    clientType: "POTENTIAL",
    pensionType: "",
    age: "",
    birthday: "",
    gmail: "",
    facebookLink: "",
    street: "",
    municipality: "",
    province: "",
    phoneNumber: ""
  });

  const handleInputChange = (field: string, value: string) => {
    setFormData(prev => ({
      ...prev,
      [field]: value
    }));
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    
    // Validate required fields
    const requiredFields = [
      'fullName', 'productType', 'marketType', 'pensionType', 
      'age', 'birthday', 'phoneNumber', 'street', 'municipality', 'province'
    ];
    
    for (const field of requiredFields) {
      if (!formData[field as keyof typeof formData]) {
        toast.error(`${field.replace(/([A-Z])/g, ' $1').toLowerCase()} is required`);
        return;
      }
    }

    // Validate age is a number
    const age = parseInt(formData.age);
    if (isNaN(age) || age < 0 || age > 120) {
      toast.error("Please enter a valid age");
      return;
    }

    // Validate phone number format (Philippine mobile number)
    if (!/^09\d{9}$/.test(formData.phoneNumber)) {
      toast.error("Please enter a valid Philippine mobile number (09XXXXXXXXX)");
      return;
    }

    try {
      // Add client
      DataService.addClient({
        ...formData,
        age
      });
      
      toast.success("Client added successfully!");
      
      // Notify parent component and go back
      onClientAdded?.();
      onBack();
      
    } catch (error) {
      toast.error("Failed to add client. Please try again.");
    }
  };

  const marketTypes = DataService.getMarketTypes();
  const productTypes = DataService.getProductTypes();
  const pensionTypes = DataService.getPensionTypes();

  return (
    <div className="bg-white flex flex-col h-full overflow-hidden">
      <MobileStatusBar />
      
      {/* Header */}
      <div className="flex items-center justify-between px-4 py-3 border-b border-gray-100 flex-shrink-0">
        <button onClick={onBack} className="p-1">
          <ArrowLeft className="w-6 h-6 text-black" />
        </button>
        <h1 className="text-lg text-black">Add Client</h1>
        <div className="w-8" />
      </div>

      {/* Form */}
      <div className="flex-1 overflow-y-auto min-h-0">
        <form onSubmit={handleSubmit} className="p-4 space-y-6">
          
          {/* Personal Information */}
          <div className="space-y-4">
            <h3 className="text-sm text-gray-500 uppercase tracking-wide">Personal Information</h3>
            
            <div>
              <Label htmlFor="fullName">Full Name *</Label>
              <Input
                id="fullName"
                placeholder="LAST NAME, FIRST NAME M.I."
                value={formData.fullName}
                onChange={(e) => handleInputChange('fullName', e.target.value.toUpperCase())}
                className="mt-1"
                required
              />
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div>
                <Label htmlFor="age">Age *</Label>
                <Input
                  id="age"
                  type="number"
                  placeholder="Age"
                  value={formData.age}
                  onChange={(e) => handleInputChange('age', e.target.value)}
                  className="mt-1"
                  min="0"
                  max="120"
                  required
                />
              </div>
              <div>
                <Label htmlFor="birthday">Birthday *</Label>
                <Input
                  id="birthday"
                  type="date"
                  value={formData.birthday}
                  onChange={(e) => handleInputChange('birthday', e.target.value)}
                  className="mt-1"
                  required
                />
              </div>
            </div>

            <div>
              <Label htmlFor="phoneNumber">Phone Number *</Label>
              <Input
                id="phoneNumber"
                placeholder="09XXXXXXXXX"
                value={formData.phoneNumber}
                onChange={(e) => handleInputChange('phoneNumber', e.target.value)}
                pattern="09\d{9}"
                maxLength={11}
                className="mt-1"
                required
              />
            </div>

            <div>
              <Label htmlFor="gmail">Email</Label>
              <Input
                id="gmail"
                type="email"
                placeholder="email@gmail.com"
                value={formData.gmail}
                onChange={(e) => handleInputChange('gmail', e.target.value)}
                className="mt-1"
              />
            </div>

            <div>
              <Label htmlFor="facebookLink">Facebook Link</Label>
              <Input
                id="facebookLink"
                placeholder="facebook.com/username"
                value={formData.facebookLink}
                onChange={(e) => handleInputChange('facebookLink', e.target.value)}
                className="mt-1"
              />
            </div>
          </div>

          {/* Address Information */}
          <div className="space-y-4">
            <h3 className="text-sm text-gray-500 uppercase tracking-wide">Address Information</h3>
            
            <div>
              <Label htmlFor="street">Street *</Label>
              <Input
                id="street"
                placeholder="Purok 1, Brgy. Example"
                value={formData.street}
                onChange={(e) => handleInputChange('street', e.target.value)}
                className="mt-1"
                required
              />
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div>
                <Label htmlFor="municipality">Municipality *</Label>
                <Input
                  id="municipality"
                  placeholder="City/Municipality"
                  value={formData.municipality}
                  onChange={(e) => handleInputChange('municipality', e.target.value)}
                  className="mt-1"
                  required
                />
              </div>
              <div>
                <Label htmlFor="province">Province *</Label>
                <Input
                  id="province"
                  placeholder="Province"
                  value={formData.province}
                  onChange={(e) => handleInputChange('province', e.target.value)}
                  className="mt-1"
                  required
                />
              </div>
            </div>
          </div>

          {/* Client Classification */}
          <div className="space-y-4">
            <h3 className="text-sm text-gray-500 uppercase tracking-wide">Client Classification</h3>
            
            <div>
              <Label htmlFor="clientType">Client Type *</Label>
              <Select value={formData.clientType} onValueChange={(value) => handleInputChange('clientType', value)}>
                <SelectTrigger className="mt-1">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="POTENTIAL">Potential</SelectItem>
                  <SelectItem value="EXISTING">Existing</SelectItem>
                </SelectContent>
              </Select>
            </div>

            <div>
              <Label htmlFor="marketType">Market Type *</Label>
              <Select value={formData.marketType} onValueChange={(value) => handleInputChange('marketType', value)}>
                <SelectTrigger className="mt-1">
                  <SelectValue placeholder="Select market type" />
                </SelectTrigger>
                <SelectContent>
                  {marketTypes.map(type => (
                    <SelectItem key={type} value={type}>{type}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>

            <div>
              <Label htmlFor="productType">Product Type *</Label>
              <Select value={formData.productType} onValueChange={(value) => handleInputChange('productType', value)}>
                <SelectTrigger className="mt-1">
                  <SelectValue placeholder="Select product type" />
                </SelectTrigger>
                <SelectContent>
                  {productTypes.map(type => (
                    <SelectItem key={type} value={type}>{type}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>

            <div>
              <Label htmlFor="pensionType">Pension Type *</Label>
              <Select value={formData.pensionType} onValueChange={(value) => handleInputChange('pensionType', value)}>
                <SelectTrigger className="mt-1">
                  <SelectValue placeholder="Select pension type" />
                </SelectTrigger>
                <SelectContent>
                  {pensionTypes.map(type => (
                    <SelectItem key={type} value={type}>{type}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
          </div>

          {/* Submit Button */}
          <div className="pt-4">
            <Button type="submit" className="w-full h-12">
              Add Client
            </Button>
          </div>
        </form>
      </div>
    </div>
  );
}