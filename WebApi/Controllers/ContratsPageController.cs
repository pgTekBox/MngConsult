using Microsoft.AspNetCore.Mvc;

// For more information on enabling Web API for empty projects, visit https://go.microsoft.com/fwlink/?LinkID=397860

namespace APIWebMngConsul.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class ContratsPageController : ControllerBase
    {
        // GET: api/<ContratsController>
        [HttpGet("{userid}")]
        public string Get(string userid)
        {
            DatabaseHelper DBHelper = new DatabaseHelper();

            Dictionary<string, object> myparams = new Dictionary<string, object>();

            myparams.Add("@UserId", userid);

            System.Data.DataSet result = DBHelper.GetDataSet("s0003GetContratByUser", myparams);
            return DBHelper.DataTableToJSONWithJSONNet(result.Tables[0]);


        }
    }
}
