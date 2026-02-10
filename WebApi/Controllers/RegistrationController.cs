using Microsoft.AspNetCore.Mvc;
using APIWebMngConsul.Models;
using Microsoft.AspNetCore.Diagnostics;
using System.Data;


namespace APIWebMngConsul.Controllers
{

    [Route("api/[controller]")]
    [ApiController]
    public class RegistrationPageController : ControllerBase
    {
        // GET: api/<ContratsController>
        [HttpGet()]
        public string Get()
        {
            DatabaseHelper DBHelper = new DatabaseHelper();
            System.Data.DataSet result = DBHelper.GetDataSet("s0011GetdefaultRegistration");
            return DBHelper.DataTableToJSONWithJSONNet(result.Tables[0]);

        }

        [HttpPost()]
        public string Post([FromBody] Registration registration )
        {
           
            
            DatabaseHelper DBHelper = new DatabaseHelper();
            Dictionary<string, object> myparams = new Dictionary<string, object>();
            myparams.Add("@Password1", registration.Password1 );
            myparams.Add("@Password2", registration.Password2);
            myparams.Add("@Firstname", registration.Firstname );
            myparams.Add("@Lastname", registration.Lastname );
            myparams.Add("@Email", registration.Email);
            myparams.Add("@AddressLine1", registration.AddressLine1);
            myparams.Add("@AddressLine2", registration.AddressLine2);
            myparams.Add("@City", registration.City);
            myparams.Add("@StateId", registration.StateId);
            myparams.Add("@CountryId", registration.CountryId);
            System.Data.DataSet result = DBHelper.GetDataSet("s0012InsertProfile", myparams);

            return DBHelper.DataTableToJSONWithJSONNet(result.Tables[0]);

        }


    }
}
