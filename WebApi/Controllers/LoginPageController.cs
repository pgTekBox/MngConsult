using Microsoft.AspNetCore.Mvc;
using System.Reflection.Metadata;
using System.Reflection.PortableExecutable;

// For more information on enabling Web API for empty projects, visit https://go.microsoft.com/fwlink/?LinkID=397860

namespace APIWebMngConsul.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class LoginPageController : ControllerBase
    {
        

        // GET api/<ValuesController>/5
        [HttpGet("{username},{password}")]
        public string Get(string username,string password )
        {

            DatabaseHelper DBHelper = new DatabaseHelper();
           
            Dictionary<string, object> myparams = new Dictionary<string, object>();

            myparams.Add("@User", username);
            myparams.Add("@Password", password);
            string result =(string) DBHelper.ExecuteScalarStringSP("s0001GetAuthentication", myparams);

            if (result == "00000000-0000-0000-0000-000000000000")
            {
                return "00000000-0000-0000-0000-000000000000";
            }
            else
            {
                return result;
            }
        }
         
        }

         
         
    }
 
