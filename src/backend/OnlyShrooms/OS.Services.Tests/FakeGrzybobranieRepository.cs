using OS.Interfaces.Repositories;
using OS.Model;

namespace OS.Services.Tests;

internal sealed class FakeGrzybobranieRepository : IGrzybobranieRepository
{
    private readonly List<Grzybobranie> _items = [];
    private int _nextId = 1;

    public Grzybobranie? LastAdded { get; private set; }

    public Grzybobranie? LastUpdated { get; private set; }

    public Task<IReadOnlyList<Grzybobranie>> GetAllAsync(CancellationToken cancellationToken = default)
        => Task.FromResult<IReadOnlyList<Grzybobranie>>(_items.ToList());

    public Task<Grzybobranie?> GetByIdAsync(int id, CancellationToken cancellationToken = default)
        => Task.FromResult(_items.SingleOrDefault(i => i.Id == id));

    public Task<Grzybobranie> AddAsync(Grzybobranie grzybobranie, CancellationToken cancellationToken = default)
    {
        grzybobranie.Id = _nextId++;
        LastAdded = grzybobranie;
        _items.Add(grzybobranie);
        return Task.FromResult(grzybobranie);
    }

    public Task<Grzybobranie?> UpdateAsync(Grzybobranie grzybobranie, CancellationToken cancellationToken = default)
    {
        LastUpdated = grzybobranie;
        var index = _items.FindIndex(i => i.Id == grzybobranie.Id);
        if (index < 0)
        {
            return Task.FromResult<Grzybobranie?>(null);
        }

        _items[index] = grzybobranie;
        return Task.FromResult<Grzybobranie?>(grzybobranie);
    }
}
