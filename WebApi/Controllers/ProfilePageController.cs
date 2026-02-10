using APIWebMngConsul.Models;
using Microsoft.AspNetCore.Mvc;

namespace APIWebMngConsul.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class ProfilePageController : ControllerBase
    {
        // GET: api/<ContratsController>
        [HttpGet("{userid}")]
        public string Get(string userid)
        {
            DatabaseHelper DBHelper = new DatabaseHelper();

            Dictionary<string, object> myparams = new Dictionary<string, object>();

            myparams.Add("@UserId", userid);

            System.Data.DataSet result = DBHelper.GetDataSet("s0004GetProfileByUser", myparams);
            return DBHelper.DataTableToJSONWithJSONNet(result.Tables[0]);


        }
        [HttpPut( )]
        public string Post([FromBody] Profile profile)
        {


            DatabaseHelper DBHelper = new DatabaseHelper();
            Dictionary<string, object> myparams = new Dictionary<string, object>();
            //myparams.Add("@Password1", registration.Password1);
            //myparams.Add("@Password2", registration.Password2);

            myparams.Add("@ProfileId", profile.Id );
            myparams.Add("@ProfileGUID", profile.GUID);
            myparams.Add("@Firstname", profile.Firstname);
            myparams.Add("@Lastname", profile.Lastname);
             
            myparams.Add("@AddressLine1", profile.AddressLine1);
            myparams.Add("@AddressLine2", profile.AddressLine2);
            myparams.Add("@City", profile.City);
            myparams.Add("@PostalCode", profile.PostalCode);
            myparams.Add("@StateId", profile.StateId);
            myparams.Add("@CountryId", profile.CountryId);
            System.Data.DataSet result = DBHelper.GetDataSet("s0013SaveProfile", myparams);

            return DBHelper.DataTableToJSONWithJSONNet(result.Tables[0]);

        }

    }
}
