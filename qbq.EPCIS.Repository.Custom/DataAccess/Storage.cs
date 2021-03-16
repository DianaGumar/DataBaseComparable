using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;

namespace qbq.EPCIS.Repository.Custom.DataAccess
{
    /// <summary>
    /// Implements the storage interface
    /// </summary>
    /// <typeparam name="T">Entity class</typeparam>
    internal class Storage<T> : IStorage<T> where T : class
    {
        private readonly DbContext _context;
        private readonly DbSet<T> _dbSet;

        /// <summary>
        /// The constructor
        /// </summary>
        /// <param name="context"></param>
        public Storage(DbContext context)
        {
            _context = context;
            _dbSet = context.Set<T>();
        }

        /// <summary>
        /// Inserts item in the database
        /// </summary>
        /// <param name="item">Item object</param>
        public void Insert(T item)
        {
            _dbSet.Add(item);
        }

        /// <summary>
        /// Inserts the range of items to the database
        /// </summary>
        /// <param name="items">Range of item objects</param>
        public void InsertRange(IEnumerable<T> items)
        {
            _dbSet.AddRange(items);
        }

        /// <summary>
        /// Reads all the data from the table
        /// </summary>
        /// <returns>Collections of item</returns>
        public IEnumerable<T> Read()
        {
            return _dbSet.AsNoTracking().ToList();
        }
    }
}
