using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;

namespace APIWebMngConsul.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class ServerInfoController : ControllerBase
    {
        // GET api/<ValuesController>/5
        [HttpGet()]
        public string Get()
        {
            DatabaseHelper DBHelper = new DatabaseHelper();
            System.Data.DataSet result = DBHelper.GetDataSet("s0009GetServerInfo");
            return DBHelper.DataTableToJSONWithJSONNet(result.Tables[0]);

        }
    }
}
 
