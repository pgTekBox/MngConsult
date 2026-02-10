 
using Microsoft.AspNetCore.Mvc;

namespace APIWebMngConsul.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class ProfileCompanyController : ControllerBase
    {

        // GET: api/<ContratsController>
        [HttpGet("{companyidId}")]
        public string Get(int companyidId)
        {
            DatabaseHelper DBHelper = new DatabaseHelper();

            Dictionary<string, object> myparams = new Dictionary<string, object>();

            myparams.Add("@CompanyId", companyidId);

            System.Data.DataSet result = DBHelper.GetDataSet("s0005GetProfileCompanyByCompanyId", myparams);
            return DBHelper.DataTableToJSONWithJSONNet(result.Tables[0]);


        }


    }
}
