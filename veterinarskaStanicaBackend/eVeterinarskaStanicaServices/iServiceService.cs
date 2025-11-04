using System;
using System.Collections.Generic;
using System.Text;
using eVeterinarskaStanicaModel;
using eVeterinarskaStanicaModel.SearchObjects;
using eVeterinarskaStanicaServices; 

namespace eVeterinarskaStanicaServices
{
    public interface iServiceService
    {
        public List<Service> Get(ServiceSearchObject search);

        public Service Get(int id);
    }
}




