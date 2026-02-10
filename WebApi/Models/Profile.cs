namespace APIWebMngConsul.Models
{
    public class Profile
    {
        public int Id { get; set; }

        public Guid GUID { get; set; }
        public string Firstname { get; set; }
        public string Lastname { get; set; }
        public string AddressLine1 { get; set; }
        public string AddressLine2 { get; set; }
        public string City { get; set; }
        public string PostalCode { get; set; }
        public int StateId { get; set; }
        public int CountryId { get; set; }


    }
}
