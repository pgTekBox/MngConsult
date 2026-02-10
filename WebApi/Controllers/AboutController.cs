 
using Microsoft.AspNetCore.Mvc;

namespace APIWebMngConsul.Controllers
{

    [Route("api/[controller]/[action]")]
    [ApiController]
    public class AboutController : ControllerBase
    {


        [ActionName("RemoveUser")]
        [HttpDelete("{userid}")]
        public string RemoveUser(string userid)
        {
            DatabaseHelper DBHelper = new DatabaseHelper();

            Dictionary<string, object> myparams = new Dictionary<string, object>();

            myparams.Add("@UserId", userid);

            System.Data.DataSet result = DBHelper.GetDataSet("s0014DeleteUser", myparams);
            return DBHelper.DataTableToJSONWithJSONNet(result.Tables[0]);
        }




        [ActionName("AddTask")]
        [HttpPut("{userid},{typeid}")]
        public string AddTask(string userid,int typeid)
        {
            DatabaseHelper DBHelper = new DatabaseHelper();

            Dictionary<string, object> myparams = new Dictionary<string, object>();

            myparams.Add("@UserId", userid);
            myparams.Add("@TypeId", typeid);
            System.Data.DataSet result = DBHelper.GetDataSet("s0015AddTaskToUser", myparams);
            return DBHelper.DataTableToJSONWithJSONNet(result.Tables[0]);
        }

        [ActionName("GetAllUsers")]
        [HttpGet()]
        public string Get()
        {
            DatabaseHelper DBHelper = new DatabaseHelper();
            System.Data.DataSet result = DBHelper.GetDataSet("s0016GetAllUsers");
            return DBHelper.DataTableToJSONWithJSONNet(result.Tables[0]);

        }

    }




    }
 