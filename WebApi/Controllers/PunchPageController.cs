 
using Microsoft.AspNetCore.Mvc;
 

 
namespace APIWebMngConsul.Controllers
{

    


    [Route("api/[controller]/[action]")]
    [ApiController]
    public class PunchPageController : ControllerBase
    {

        [ActionName("UpdateTask")]
        [HttpPut("{taskid},{running}")]
        public string UpdateTask(int taskid,int running)
        {

           
            DatabaseHelper DBHelper = new DatabaseHelper();

            Dictionary<string, object> myparams = new Dictionary<string, object>();

            myparams.Add("@TaskId", taskid);
            myparams.Add("@Running", running);

            System.Data.DataSet result = DBHelper.GetDataSet("s0008SetTaskStartStop", myparams);
            return DBHelper.DataTableToJSONWithJSONNet(result.Tables[0]);
        }

        [ActionName("Get")]
        [HttpGet("{userid}")]
        public string  Get(string userid)
        {
            DatabaseHelper DBHelper = new DatabaseHelper();
            
            Dictionary<string, object> myparams = new Dictionary<string, object>();

            myparams.Add("@UserId", userid);

            System.Data.DataSet result =  DBHelper.GetDataSet("s0002GetTaskByUser", myparams);
            return DBHelper.DataTableToJSONWithJSONNet( result.Tables[0] ) ;

             
        }




        [ActionName("TaskQuantity")]
        [HttpPut("{taskid},{quantity}")]
        public string TaskQuantity(int taskid, float quantity)
        {
            DatabaseHelper DBHelper = new DatabaseHelper();
            Dictionary<string, object> myparams = new Dictionary<string, object>();

            myparams.Add("@TaskId", taskid);
            myparams.Add("@Quantity", quantity);

            System.Data.DataSet result = DBHelper.GetDataSet("s0018UpdateQuantity", myparams);

            return DBHelper.DataTableToJSONWithJSONNet(result.Tables[0]);

        }



        [ActionName("TimeEntry")]
        [HttpPut("{taskid},{timeentryseconde}")]
        public string TimeEntry(int taskid, string timeentryseconde)
        {


            DatabaseHelper DBHelper = new DatabaseHelper();
            Dictionary<string, object> myparams = new Dictionary<string, object>();

            myparams.Add("@TaskId", taskid);
            myparams.Add("@TimeEntry", timeentryseconde);

            System.Data.DataSet result = DBHelper.GetDataSet("s0017UpdateTimeEntry", myparams);

            return DBHelper.DataTableToJSONWithJSONNet(result.Tables[0]);

        }







    }
}
