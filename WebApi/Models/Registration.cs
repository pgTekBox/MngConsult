
namespace APIWebMngConsul.Models
{
    public class Registration
    {

        //public int Id { get; set; }
        //public Guid GUID { get; set; }
        public string Email { get; set; }
        public string Password1 { get; set; }
        public string Password2 { get; set; }
        public string Firstname { get; set; }
        public string Lastname { get; set; }
        public string AddressLine1 { get; set; }
        public string AddressLine2 { get; set; }
        public string City { get; set; }
        public int StateId { get; set; }
        public int CountryId { get; set; }
        

    }
}